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
