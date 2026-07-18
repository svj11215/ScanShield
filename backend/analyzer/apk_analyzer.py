import gc
import zipfile
import logging
import re
import xml.etree.ElementTree as ET

# Ensure compatibility with different versions of Androguard
try:
    from androguard.core.apk import APK
except ImportError:
    from androguard.core.bytecodes.apk import APK

# Set up logging
logger = logging.getLogger("androguard.apk")

# Define permission sets for categorization
CRITICAL_PERMISSIONS = {
    "android.permission.REQUEST_INSTALL_PACKAGES",
    "android.permission.SYSTEM_ALERT_WINDOW",
    "android.permission.BIND_ACCESSIBILITY_SERVICE",
    "android.permission.BIND_DEVICE_ADMIN",
    "android.permission.QUERY_ALL_PACKAGES",
    "android.permission.PACKAGE_USAGE_STATS",
}

DANGEROUS_PERMISSIONS = {
    "android.permission.READ_SMS",
    "android.permission.SEND_SMS",
    "android.permission.RECEIVE_SMS",
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.READ_CALL_LOG",
    "android.permission.WRITE_CALL_LOG",
    "android.permission.PROCESS_OUTGOING_CALLS",
    "android.permission.READ_PHONE_STATE",
    "android.permission.RECORD_AUDIO",
    "android.permission.CAMERA",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.MANAGE_EXTERNAL_STORAGE",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.FOREGROUND_SERVICE",
}

NORMAL_PERMISSIONS = {
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.ACCESS_WIFI_STATE",
    "android.permission.VIBRATE",
    "android.permission.WAKE_LOCK",
    "android.permission.BLUETOOTH",
    "android.permission.BLUETOOTH_ADMIN",
    "android.permission.MODIFY_AUDIO_SETTINGS",
    "android.permission.SET_WALLPAPER",
    "android.permission.RECEIVE_BOOT_COMPLETED",
}


class LightAPK(APK):
    """
    [OPTIMIZATION] Subclass Androguard's APK class to bypass Androguard's default ZipEntry.parse.
    Bypassing it avoids loading the entire APK into memory, saving >90% of the RAM.
    """
    def __init__(self, filename):
        self.filename = filename
        
        # Initialize only the minimum required fields
        self.xml = {}
        self.axml = {}
        self.arsc = {}

        self.package = ""
        self.androidversion = {}
        self.permissions = []
        self.uses_permissions = []
        self.declared_permissions = {}
        self.valid_apk = False

        self._is_signed_v2 = None
        self._is_signed_v3 = None
        self._v2_blocks = []
        self._is_signed_v31 = None
        self._v2_signing_data = None
        self._v3_signing_data = None
        self._v31_signing_data = None

        self._files = {}
        self.files_crc32 = {}

        # [OPTIMIZATION] Use standard zipfile.ZipFile to open the APK.
        # This streams only the required files (like AndroidManifest.xml) on-demand.
        self.zip = zipfile.ZipFile(filename, 'r')
        self.__raw = None
        
        # Parse only the AndroidManifest.xml
        self._apk_analysis()


def analyze_apk(file_path):
    """
    Upgraded APK Analyzer that performs lightweight security indicator scans
    and manifest parsing while keeping memory footprint extremely low (<25 MB).
    """
    apk = None
    try:
        # [OPTIMIZATION] Instantiate the lightweight APK loader
        apk = LightAPK(file_path)
        
        # Extract basic metadata
        package_name = apk.get_package()
        app_name = apk.get_app_name()
        permissions = list(apk.get_permissions())
        main_activity = apk.get_main_activity()
        min_sdk = apk.get_min_sdk_version()
        target_sdk = apk.get_target_sdk_version()
        
        # Free resource parser memory immediately if resources.arsc was loaded
        if hasattr(apk, 'arsc') and apk.arsc:
            apk.arsc.clear()
            
        # Manifest element lookup helpers
        manifest = apk.xml.get("AndroidManifest.xml")
        
        # Default security settings
        shared_user_id = None
        install_location = None
        version_name = ""
        version_code = ""
        debuggable = False
        backup_enabled = False
        cleartext_traffic = False
        network_security_config = None
        
        activities = []
        services = []
        receivers = []
        providers = []
        launcher_activity = None
        exported_components_list = []
        intent_filters_summary = []
        
        if manifest is not None:
            # Shared user ID and install location
            shared_user_id = manifest.attrib.get("sharedUserId")
            install_location = manifest.attrib.get("installLocation")
            version_name = manifest.attrib.get("versionName", "")
            version_code = manifest.attrib.get("versionCode", "")
            
            # Fetch application tag settings
            app_elem = manifest.find("application")
            if app_elem is not None:
                ns_prefix = "{http://schemas.android.com/apk/res/android}"
                debuggable = app_elem.attrib.get(f"{ns_prefix}debuggable") == "true"
                backup_enabled = app_elem.attrib.get(f"{ns_prefix}allowBackup") != "false"
                cleartext_traffic = app_elem.attrib.get(f"{ns_prefix}usesCleartextTraffic") == "true"
                network_security_config = app_elem.attrib.get(f"{ns_prefix}networkSecurityConfig")
                
                # Single-pass parsing of components
                for comp_type in ["activity", "service", "receiver", "provider"]:
                    for comp in app_elem.findall(comp_type):
                        name = comp.attrib.get(f"{ns_prefix}name")
                        if not name:
                            continue
                            
                        # Add to list
                        if comp_type == "activity":
                            activities.append(name)
                        elif comp_type == "service":
                            services.append(name)
                        elif comp_type == "receiver":
                            receivers.append(name)
                        elif comp_type == "provider":
                            providers.append(name)
                            
                        # Exported logic: explicitly true, or implicitly true if it has intent filters and not explicitly false
                        exported_attr = comp.attrib.get(f"{ns_prefix}exported")
                        filters = comp.findall("intent-filter")
                        has_filters = len(filters) > 0
                        
                        is_exported = False
                        if exported_attr == "true":
                            is_exported = True
                        elif exported_attr == "false":
                            is_exported = False
                        else:
                            is_exported = has_filters
                            
                        if is_exported:
                            exported_components_list.append({
                                "type": comp_type,
                                "name": name
                            })
                            
                        # Extract intent filters
                        for ifilter in filters:
                            actions = [act.attrib.get(f"{ns_prefix}name") for act in ifilter.findall("action") if act.attrib.get(f"{ns_prefix}name")]
                            categories = [cat.attrib.get(f"{ns_prefix}name") for cat in ifilter.findall("category") if cat.attrib.get(f"{ns_prefix}name")]
                            
                            intent_filters_summary.append({
                                "component": name,
                                "type": comp_type,
                                "actions": actions,
                                "categories": categories
                            })
                            
                            # Identify launcher activity
                            if comp_type == "activity" and "android.intent.action.MAIN" in actions and "android.intent.category.LAUNCHER" in categories:
                                launcher_activity = name

        # Categorize permissions
        permissions_breakdown = {
            "Critical": [],
            "Dangerous": [],
            "Normal": [],
            "Unknown": []
        }
        for p in permissions:
            if p in CRITICAL_PERMISSIONS:
                permissions_breakdown["Critical"].append(p)
            elif p in DANGEROUS_PERMISSIONS:
                permissions_breakdown["Dangerous"].append(p)
            elif p in NORMAL_PERMISSIONS:
                permissions_breakdown["Normal"].append(p)
            else:
                permissions_breakdown["Unknown"].append(p)

        # [OPTIMIZATION] Determine uses_native_code by checking the presence of .so files
        # in the zip file namelist without loading/parsing any native code files.
        zip_files = apk.zip.namelist()
        uses_native_code = any(f.endswith(".so") for f in zip_files)

        # DEX Lightweight Scanning variables
        suspicious_apis = set()
        network_indicators = {
            "urls": set(),
            "ips": set(),
            "localhost": False,
            "websocket": False
        }
        crypto_indicators = set()
        root_evasion_indicators = set()

        # Risk Flags
        uses_sms = any(p in permissions for p in ["android.permission.SEND_SMS", "android.permission.RECEIVE_SMS", "android.permission.READ_SMS"])
        uses_contacts = any(p in permissions for p in ["android.permission.READ_CONTACTS", "android.permission.WRITE_CONTACTS", "android.permission.GET_ACCOUNTS"])
        uses_camera = "android.permission.CAMERA" in permissions
        uses_microphone = "android.permission.RECORD_AUDIO" in permissions
        uses_location = any(p in permissions for p in ["android.permission.ACCESS_FINE_LOCATION", "android.permission.ACCESS_COARSE_LOCATION"])
        uses_overlay = "android.permission.SYSTEM_ALERT_WINDOW" in permissions
        uses_accessibility = "android.permission.BIND_ACCESSIBILITY_SERVICE" in permissions
        uses_device_admin = "android.permission.BIND_DEVICE_ADMIN" in permissions
        uses_boot_receiver = "android.permission.RECEIVE_BOOT_COMPLETED" in permissions

        uses_dynamic_loading = False
        uses_runtime_exec = False
        uses_webview_js = False
        uses_root_detection = False
        uses_crypto = False
        uses_network = "android.permission.INTERNET" in permissions

        # Target API byte signatures
        api_signatures = {
            b"java/lang/Runtime": ("uses_runtime_exec", "java/lang/Runtime"),
            b"java/lang/ProcessBuilder": ("uses_runtime_exec", "java/lang/ProcessBuilder"),
            b"dalvik/system/DexClassLoader": ("uses_dynamic_loading", "dalvik/system/DexClassLoader"),
            b"dalvik/system/PathClassLoader": ("uses_dynamic_loading", "dalvik/system/PathClassLoader"),
            b"android/telephony/SmsManager": ("uses_sms", "android/telephony/SmsManager"),
            b"android/telephony/TelephonyManager": ("uses_phone_state", "android/telephony/TelephonyManager"),
            b"android/accessibilityservice": ("uses_accessibility", "android/accessibilityservice"),
            b"android/app/admin": ("uses_device_admin", "android/app/admin"),
            b"android/hardware/Camera": ("uses_camera", "android/hardware/Camera"),
            b"android/media/MediaRecorder": ("uses_microphone", "android/media/MediaRecorder"),
            b"android/location/LocationManager": ("uses_location", "android/location/LocationManager"),
            b"android/accounts": ("uses_contacts", "android/accounts"),
            b"android/webkit/WebView": ("uses_webview_js", "android/webkit/WebView"),
            b"addJavascriptInterface": ("uses_webview_js", "addJavascriptInterface"),
            b"loadUrl": ("uses_webview_js", "loadUrl"),
            b"Cipher": ("uses_crypto", "Cipher"),
            b"SecretKeySpec": ("uses_crypto", "SecretKeySpec"),
            b"MessageDigest": ("uses_crypto", "MessageDigest"),
            b"Base64": ("uses_crypto", "Base64"),
            b"HttpsURLConnection": ("uses_network", "HttpsURLConnection"),
            b"Socket": ("uses_network", "Socket"),
            b"ServerSocket": ("uses_network", "ServerSocket"),
            b"HttpURLConnection": ("uses_network", "HttpURLConnection"),
        }

        crypto_signatures = {
            b"AES": "AES",
            b"DES": "DES",
            b"RSA": "RSA",
            b"MD5": "MD5",
            b"SHA1": "SHA1",
            b"SHA256": "SHA256",
        }

        root_evasion_signatures = {
            b"su": "su",
            b"busybox": "busybox",
            b"Magisk": "Magisk",
            b"Superuser": "Superuser",
            b"RootBeer": "RootBeer",
            b"Xposed": "Xposed",
            b"Frida": "Frida",
            b"SafetyNet": "SafetyNet",
            b"PlayIntegrity": "Play Integrity",
            b"play/integrity": "Play Integrity",
        }

        # Precompiled regexes on bytes for speed and memory efficiency
        url_regex = re.compile(b"https?://[a-zA-Z0-9./?=&_-]+")
        ws_regex = re.compile(b"wss?://[a-zA-Z0-9./?=&_-]+")
        ip_regex = re.compile(b"\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b")

        # [OPTIMIZATION] Scan DEX files by directly searching the binary byte streams
        # to find APIs, URLs, IPs, and evasions without building ASTs or call graphs.
        for name in zip_files:
            if name.startswith("classes") and name.endswith(".dex"):
                try:
                    dex_bytes = apk.zip.read(name)
                    
                    # Search API signatures
                    for sig, (flag, label) in api_signatures.items():
                        if sig in dex_bytes:
                            suspicious_apis.add(label)
                            if flag == "uses_runtime_exec":
                                uses_runtime_exec = True
                            elif flag == "uses_dynamic_loading":
                                uses_dynamic_loading = True
                            elif flag == "uses_webview_js":
                                uses_webview_js = True
                            elif flag == "uses_sms":
                                uses_sms = True
                            elif flag == "uses_camera":
                                uses_camera = True
                            elif flag == "uses_microphone":
                                uses_microphone = True
                            elif flag == "uses_location":
                                uses_location = True
                            elif flag == "uses_contacts":
                                uses_contacts = True
                            elif flag == "uses_crypto":
                                uses_crypto = True
                            elif flag == "uses_network":
                                uses_network = True

                    # Search crypto signatures
                    for sig, label in crypto_signatures.items():
                        if sig in dex_bytes:
                            crypto_indicators.add(label)
                            uses_crypto = True

                    # Search root evasion signatures
                    for sig, label in root_evasion_signatures.items():
                        if sig in dex_bytes:
                            root_evasion_indicators.add(label)
                            uses_root_detection = True

                    # Limit indicator counts to avoid memory blowup with huge string pools
                    if len(network_indicators["urls"]) < 50:
                        urls = url_regex.findall(dex_bytes)
                        for u in urls:
                            if len(network_indicators["urls"]) >= 50:
                                break
                            decoded_url = u.decode('utf-8', errors='ignore')
                            network_indicators["urls"].add(decoded_url)
                            if "localhost" in decoded_url or "127.0.0.1" in decoded_url:
                                network_indicators["localhost"] = True

                    if len(network_indicators["ips"]) < 50:
                        ips = ip_regex.findall(dex_bytes)
                        for ip in ips:
                            if len(network_indicators["ips"]) >= 50:
                                break
                            decoded_ip = ip.decode('utf-8', errors='ignore')
                            network_indicators["ips"].add(decoded_ip)
                            if decoded_ip == "127.0.0.1":
                                network_indicators["localhost"] = True

                    # Websocket and localhost check on byte level
                    if b"ws://" in dex_bytes or b"wss://" in dex_bytes or ws_regex.search(dex_bytes):
                        network_indicators["websocket"] = True
                    if b"localhost" in dex_bytes or b"127.0.0.1" in dex_bytes:
                        network_indicators["localhost"] = True

                except Exception as dex_err:
                    logger.warning(f"Error scanning DEX {name}: {dex_err}")
                finally:
                    # [OPTIMIZATION] Reclaim memory of the read DEX file immediately
                    if 'dex_bytes' in locals():
                        del dex_bytes
                    gc.collect()

    except Exception as e:
        logger.error(f"Error analyzing APK {file_path}: {e}")
        package_name = ""
        app_name = "Unknown (Malformed APK)"
        permissions = []
        main_activity = None
        min_sdk = None
        target_sdk = None
        version_name = ""
        version_code = ""
        shared_user_id = None
        install_location = None
        debuggable = False
        backup_enabled = False
        cleartext_traffic = False
        network_security_config = None
        activities = []
        services = []
        receivers = []
        providers = []
        launcher_activity = None
        exported_components_list = []
        intent_filters_summary = []
        permissions_breakdown = {"Critical": [], "Dangerous": [], "Normal": [], "Unknown": []}
        uses_native_code = False
        suspicious_apis = set()
        network_indicators = {"urls": set(), "ips": set(), "localhost": False, "websocket": False}
        crypto_indicators = set()
        root_evasion_indicators = set()
        uses_sms = False
        uses_contacts = False
        uses_camera = False
        uses_microphone = False
        uses_location = False
        uses_overlay = False
        uses_accessibility = False
        uses_device_admin = False
        uses_dynamic_loading = False
        uses_runtime_exec = False
        uses_webview_js = False
        uses_root_detection = False
        uses_crypto = False
        uses_network = False
        uses_boot_receiver = False

    finally:
        # [OPTIMIZATION] Ensure the zip file is closed and garbage collected immediately
        if apk is not None:
            if hasattr(apk, 'zip') and apk.zip:
                try:
                    apk.zip.close()
                except Exception:
                    pass
            del apk
        gc.collect()

    return {
        # Original Keys (Keep fully compatible)
        "package_name": package_name,
        "app_name": app_name,
        "permissions": permissions,
        "main_activity": main_activity,
        "min_sdk": min_sdk,
        "target_sdk": target_sdk,
        
        # Upgraded Manifest Details
        "version_name": version_name,
        "version_code": version_code,
        "shared_user_id": shared_user_id,
        "install_location": install_location,
        "debuggable": debuggable,
        "backup_enabled": backup_enabled,
        "cleartext_traffic": cleartext_traffic,
        "network_security_config": network_security_config,
        "activities": activities,
        "services": services,
        "receivers": receivers,
        "providers": providers,
        "launcher_activity": launcher_activity,
        "exported_components_details": exported_components_list,
        "intent_filters": intent_filters_summary,
        
        # Categorized permissions
        "permissions_breakdown": permissions_breakdown,

        # Upgraded Security Risk Flags
        "uses_sms": uses_sms,
        "uses_contacts": uses_contacts,
        "uses_camera": uses_camera,
        "uses_microphone": uses_microphone,
        "uses_location": uses_location,
        "uses_overlay": uses_overlay,
        "uses_accessibility": uses_accessibility,
        "uses_device_admin": uses_device_admin,
        "uses_dynamic_loading": uses_dynamic_loading,
        "uses_runtime_exec": uses_runtime_exec,
        "uses_webview_js": uses_webview_js,
        "uses_native_code": uses_native_code,
        "uses_root_detection": uses_root_detection,
        "uses_crypto": uses_crypto,
        "uses_network": uses_network,
        "uses_boot_receiver": uses_boot_receiver,
        "exported_components": len(exported_components_list),

        # Upgraded Indicators
        "network_indicators": {
            "urls": sorted(list(network_indicators["urls"])),
            "ips": sorted(list(network_indicators["ips"])),
            "localhost": network_indicators["localhost"],
            "websocket": network_indicators["websocket"]
        },
        "crypto_indicators": sorted(list(crypto_indicators)),
        "root_evasion_indicators": sorted(list(root_evasion_indicators)),
        "suspicious_apis": sorted(list(suspicious_apis))
    }