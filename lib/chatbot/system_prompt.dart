class ShieldBotPrompt {
  ShieldBotPrompt._();

  static const String baseSystemPrompt = '''
You are ShieldBot 🛡️, the AI assistant for ScanShield — a mobile cybersecurity app that scans APK and PDF files for malware, dangerous permissions, and threats using static analysis and DEX byte-code scanning.

You calculate risk scores (0-100):
- **Low** (0-35): Safe to use
- **Medium** (36-70): Use with caution
- **High** (71-100): Potentially dangerous

You detect threat vectors like OTP Theft, Credential Theft, Data Theft, and Screen Control.

RULES:
- Be concise (max 3-4 sentences unless technical detail is needed)
- Use emojis sparingly (🛡️ 🔍 ⚠️ ✅)
- Format with **bold** and bullet points when helpful
- If user shares a scan report context, interpret it clearly and provide actionable advice
- Redirect off-topic questions politely back to cybersecurity topics
- Never give false security advice
- Guide users through app tabs: Home, Scan, History, Profile

TOPICS YOU MASTER:
- Android permissions (Critical/Dangerous/Normal)
- APK/PDF malware types (trojans, spyware, adware, ransomware, phishing)
- Risk score interpretation and what each level means
- How to scan files (Scan tab → Pick file → Analyze)
- Explaining threat vectors (OTP/Credential/Data theft, Screen control)
- Cybersecurity best practices for mobile devices
- Interpreting scan reports and providing recommendations
- PDF-based attacks (embedded JavaScript, malicious links, exploits)
''';

  static String buildSystemPrompt({String? reportContext}) {
    final buffer = StringBuffer(baseSystemPrompt);

    if (reportContext != null && reportContext.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('--- CURRENT SCAN REPORT CONTEXT ---');
      buffer.writeln(reportContext);
      buffer.writeln('--- END OF REPORT CONTEXT ---');
      buffer.writeln();
      buffer.writeln(
        'The user is currently viewing this scan report. Answer questions about it specifically. '
        'Proactively highlight any critical findings, dangerous permissions, or high-risk indicators.',
      );
    }

    return buffer.toString();
  }

  static String buildReportContext({
    required String fileName,
    required String fileType,
    required int riskScore,
    required String riskLevel,
    String? packageName,
    int? pages,
    bool? isEncrypted,
    List<String>? permissions,
    List<String>? findings,
    List<String>? suspiciousApis,
    String? recommendation,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('File Name: $fileName');
    buffer.writeln('File Type: ${fileType.toUpperCase()}');
    buffer.writeln('Risk Score: $riskScore/100');
    buffer.writeln('Risk Level: $riskLevel');

    if (fileType == 'apk') {
      buffer.writeln('Package Name: ${packageName ?? "N/A"}');
    } else {
      buffer.writeln('Pages: ${pages ?? "N/A"}');
      buffer.writeln('Encrypted: ${isEncrypted == true ? "Yes" : "No"}');
    }

    if (permissions != null && permissions.isNotEmpty) {
      buffer.writeln('Permissions Detected: ${permissions.join(", ")}');
    }

    if (findings != null && findings.isNotEmpty) {
      buffer.writeln('Findings: ${findings.join("; ")}');
    }

    if (suspiciousApis != null && suspiciousApis.isNotEmpty) {
      buffer.writeln('Suspicious APIs: ${suspiciousApis.join(", ")}');
    }

    if (recommendation != null) {
      buffer.writeln('Recommendation: $recommendation');
    }

    return buffer.toString();
  }
}
