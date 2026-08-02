class AppConstants {
  AppConstants._();

  static const String appName = 'ScanShield';
  static const String appTagline = 'Your Shield Against Malicious Apps';
  
  // 🔴 REPLACE with your actual Render URL
  static const String apiBaseUrl = 'https://scanshield-backend.onrender.com';
  
  static const String apiScanEndpoint = '/analyze';
  static const String apiHealthEndpoint = '/';
  
  static const Duration apiTimeout = Duration(minutes: 5);
  static const int maxFileSizeMB = 100;

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  // ─── Did You Know Facts Pool ───
  static const List<String> didYouKnowFacts = [
    'Over ₹36,000 crore was lost to banking fraud in India this year. Always verify banking app sources before installing.',
    'More than 90% of cyberattacks begin with a phishing email. Never click links from unknown senders.',
    'Malicious APK files can silently read your SMS messages and steal OTPs, giving attackers full access to your bank accounts.',
    'PDFs can contain hidden JavaScript that executes when opened, potentially downloading malware to your device.',
    'India reported over 14 lakh cyber crime incidents in 2023, a 113% increase from the previous year.',
    'A single malicious app can request 20+ dangerous permissions — including access to your camera, microphone, and contacts.',
    'Cybercrime damages are projected to reach \$10.5 trillion globally by 2025, making it more profitable than the global illegal drug trade.',
    'Nearly 1 in 3 Android malware variants disguise themselves as system utility or security apps to gain user trust.',
    'Side-loaded APKs bypass Google Play Protect checks, making them 8x more likely to contain malware than Play Store apps.',
    'Credential-stuffing attacks use leaked password databases to try millions of login combinations automatically — use unique passwords for every account.',
    'Screen overlay attacks can place invisible layers on your banking app, capturing every tap and keystroke you make.',
    'A compromised PDF viewer app can be exploited to access all files on your device through permission escalation vulnerabilities.',
  ];

  // ─── Professional Scan Status Messages ───
  static const List<String> scanStatusMessages = [
    'Initializing secure analysis environment...',
    'Reading file structure and metadata...',
    'Scanning for embedded threats and anomalies...',
    'Verifying permissions and access patterns...',
    'Cross-referencing known threat signatures...',
    'Analyzing behavioral risk indicators...',
    'Validating file integrity and certificates...',
    'Compiling risk assessment report...',
    'Finalizing results — almost there...',
  ];
}

class AppSizes {
  AppSizes._();

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 16.0;
}

class AppStrings {
  AppStrings._();

  static const String loginTitle = 'Welcome Back';
  static const String signupTitle = 'Create Account';
  static const String scanButtonText = 'Scan Device';
  static const String securityStatusSafe = 'No Threats Found';
  static const String securityStatusSuspicious = 'Suspicious Apps Found';
  static const String securityStatusMalicious = 'Threats Detected!';
  static const String scanInProgress = 'Scanning your device...';
  static const String startScanning = 'Tap the button to start scanning your applications for security risks.';
}
