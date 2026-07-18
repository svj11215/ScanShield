const Map<String, String> permissionDescriptions = {
  // Dangerous/Sensitive Permissions
  "SEND_SMS": "Allows the app to send SMS messages. This can result in unexpected charges or premium subscription fraud.",
  "RECEIVE_SMS": "Allows the app to intercept and read incoming SMS messages. Often abused to capture OTP verification codes.",
  "READ_SMS": "Allows the app to read SMS messages stored on your device. Highly sensitive for banking and OTP verification.",
  "READ_CONTACTS": "Allows the app to read your contact list, potentially exposing names, phone numbers, and emails to remote servers.",
  "WRITE_CONTACTS": "Allows the app to create, edit, or delete contacts in your address book.",
  "ACCESS_FINE_LOCATION": "Allows the app to obtain your precise GPS location, enabling tracking of your physical movements.",
  "ACCESS_COARSE_LOCATION": "Allows the app to access your approximate location based on network sources (cell towers, Wi-Fi).",
  "RECORD_AUDIO": "Allows the app to access the microphone to record audio. Could be abused for background eavesdropping.",
  "CAMERA": "Allows the app to take pictures and record videos. Could be abused to capture media without your knowledge.",
  "READ_PHONE_STATE": "Allows the app to access phone features, including your phone number, current cellular network info, and ongoing call status.",
  "CALL_PHONE": "Allows the app to initiate phone calls without user interaction, potentially costing you money.",
  "PROCESS_OUTGOING_CALLS": "Allows the app to monitor, redirect, or block outgoing calls.",
  "ADD_VOICEMAIL": "Allows the app to add messages to your voicemail inbox.",
  "USE_SIP": "Allows the app to make and receive SIP calls.",
  "SYSTEM_ALERT_WINDOW": "Allows the app to show overlay windows on top of all other apps. Often used in screen hijacking or phishing attacks.",
  "WRITE_EXTERNAL_STORAGE": "Allows the app to write files to your device's external storage, potentially altering other application files.",
  "READ_EXTERNAL_STORAGE": "Allows the app to read files on your external storage (photos, media, documents).",
  "MANAGE_EXTERNAL_STORAGE": "Grants broad access to external storage. Extremely sensitive as it bypasses normal media restrictions.",
  "BIND_ACCESSIBILITY_SERVICE": "Allows the app to run as an Accessibility Service. Highly dangerous; malicious apps use this to intercept screen content and simulate taps.",
  "REQUEST_INSTALL_PACKAGES": "Allows the app to request installing other packages/APKs, which could lead to stealthy drive-by malware installations.",
  
  // Normal/Common Permissions
  "INTERNET": "Allows the app to create network sockets and access the internet. Required for most cloud-based functions.",
  "ACCESS_NETWORK_STATE": "Allows the app to view information about network connections, such as whether Wi-Fi or cellular data is active.",
  "ACCESS_WIFI_STATE": "Allows the app to view information about Wi-Fi networks.",
  "WAKE_LOCK": "Allows the app to prevent the processor from sleeping or the screen from dimming during long processes.",
  "VIBRATE": "Allows the app to control the vibration feedback of the device.",
  "RECEIVE_BOOT_COMPLETED": "Allows the app to start automatically as soon as the system finishes booting. Often used to launch background services.",
  "FOREGROUND_SERVICE": "Allows the app to run foreground services, keeping the application active even when not in focus.",
  "GET_TASKS": "Allows the app to retrieve information about current or recently running tasks.",
  "KILL_BACKGROUND_PROCESSES": "Allows the app to terminate background processes of other applications.",
};

String getPermissionDescription(String permission) {
  // Normalize key (remove android.permission. prefix if present)
  final normalizedKey = permission.replaceAll('android.permission.', '').toUpperCase();
  return permissionDescriptions[normalizedKey] ?? "Allows the application to request the $permission permission.";
}

bool isDangerousPermission(String permission) {
  final dangerous = [
    "SEND_SMS", "RECEIVE_SMS", "READ_SMS", "READ_CONTACTS", "WRITE_CONTACTS",
    "ACCESS_FINE_LOCATION", "RECORD_AUDIO", "CAMERA", "READ_PHONE_STATE",
    "CALL_PHONE", "SYSTEM_ALERT_WINDOW", "BIND_ACCESSIBILITY_SERVICE",
    "REQUEST_INSTALL_PACKAGES", "MANAGE_EXTERNAL_STORAGE"
  ];
  final normalizedKey = permission.replaceAll('android.permission.', '').toUpperCase();
  return dangerous.contains(normalizedKey);
}
