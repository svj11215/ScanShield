import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/theme.dart';
import '../utils/recommendation_helper.dart';

class ScanModel {
  final String id;
  final String userId;
  final String fileName;
  final String fileType;
  final String? packageName;
  final String? appName;
  final List<String>? permissions;
  final int? pages;
  final bool? isEncrypted;
  final Map<String, dynamic>? metadata;
  final int overallRisk;
  final String riskLevel;
  final DateTime scannedAt;

  ScanModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileType,
    this.packageName,
    this.appName,
    this.permissions,
    this.pages,
    this.isEncrypted,
    this.metadata,
    required this.overallRisk,
    required this.riskLevel,
    required this.scannedAt,
  });

  // Backward compatibility getters
  int get riskScore => overallRisk;
  String get apkName => fileName;
  List<String> get permissionsDetected => permissions ?? [];
  List<String> get findings {
    // Return a list with the summary of findings
    final summary = RecommendationHelper.getFindingsSummary(toMap(), fileType);
    return summary == 'No specific findings' ? [] : summary.split('\n');
  }
  List<String> get suspiciousApis => [];
  String get recommendation => RecommendationHelper.getRecommendation(riskLevel);
  int get scanDurationSec => 5;

  Color get riskColor {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      case 'low':
      default:
        return AppColors.safe;
    }
  }

  factory ScanModel.fromMap(Map<String, dynamic> map, String docId) {
    return ScanModel(
      id: docId,
      userId: map['user_id'] ?? '',
      fileName: map['file_name'] ?? map['apk_name'] ?? 'Unknown File',
      fileType: map['file_type'] ?? 'apk',
      packageName: map['package_name'],
      appName: map['app_name'],
      permissions: map['permissions'] != null ? List<String>.from(map['permissions']) : null,
      pages: map['pages'],
      isEncrypted: map['is_encrypted'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      overallRisk: map['overall_risk'] ?? map['risk_score'] ?? 0,
      riskLevel: map['risk_level'] ?? 'Low',
      scannedAt: (map['scanned_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'file_name': fileName,
      'file_type': fileType,
      'overall_risk': overallRisk,
      'risk_level': riskLevel,
      'scanned_at': Timestamp.fromDate(scannedAt),
    };
    if (packageName != null) map['package_name'] = packageName;
    if (appName != null) map['app_name'] = appName;
    if (permissions != null) map['permissions'] = permissions;
    if (pages != null) map['pages'] = pages;
    if (isEncrypted != null) map['is_encrypted'] = isEncrypted;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }
}
