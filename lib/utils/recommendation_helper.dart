class RecommendationHelper {
  static String getRecommendation(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return 'This file appears safe. However, always download from trusted sources.';
      case 'medium':
        return 'Exercise caution. Review permissions and metadata before proceeding.';
      case 'high':
        return '⛔ DO NOT INSTALL/OPEN. This file poses a serious security threat.';
      default:
        return 'Unable to determine risk. Proceed with caution.';
    }
  }
  
  static String getFindingsSummary(Map<String, dynamic> data, String fileType) {
    List<String> findings = [];
    
    if (fileType == 'apk') {
      final permissions = data['permissions'] as List?;
      if (permissions != null && permissions.isNotEmpty) {
        findings.add('${permissions.length} permissions requested');
        if (permissions.any((p) => p.toString().contains('SMS'))) {
          findings.add('⚠️ Requests SMS access');
        }
        if (permissions.any((p) => p.toString().contains('CONTACTS'))) {
          findings.add('⚠️ Requests contacts access');
        }
      }
    } else if (fileType == 'pdf') {
      if (data['is_encrypted'] == true) {
        findings.add('🔒 PDF is encrypted');
      }
      final pages = data['pages'];
      if (pages != null) {
        findings.add('📄 $pages pages');
      }
    }
    
    return findings.isEmpty ? 'No specific findings' : findings.join('\n');
  }
}
