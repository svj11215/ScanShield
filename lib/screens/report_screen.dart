import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/scan_model.dart';
import '../services/firestore_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../widgets/risk_score_circle.dart';
import '../widgets/section_header.dart';
import '../widgets/info_row.dart';
import '../widgets/permission_chip.dart';

class ReportScreen extends StatefulWidget {
  final ScanModel? scanModel;
  final Map<String, dynamic>? scanData;

  const ReportScreen({
    super.key,
    this.scanModel,
    this.scanData,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late ScanModel _scan;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.scanModel != null) {
      _scan = widget.scanModel!;
    } else if (widget.scanData != null) {
      _scan = ScanModel.fromMap(widget.scanData!, '');
    } else {
      // Fallback empty model
      _scan = ScanModel(
        id: '',
        userId: '',
        fileName: 'No Data',
        fileType: 'apk',
        packageName: 'no.data',
        overallRisk: 0,
        riskLevel: 'Low',
        scannedAt: DateTime.now(),
      );
    }
  }

  Color get _riskColor => _scan.riskColor;

  String get _badgeText {
    switch (_scan.riskLevel.toLowerCase()) {
      case 'high':
      case 'malicious':
        return '🚨 HIGH RISK';
      case 'medium':
      case 'suspicious':
        return '⚠️ MEDIUM RISK';
      case 'low':
      case 'safe':
      default:
        return '✅ LOW RISK';
    }
  }

  IconData get _recommendationIcon {
    switch (_scan.riskLevel.toLowerCase()) {
      case 'high':
      case 'malicious':
        return Icons.gpp_bad_rounded;
      case 'medium':
      case 'suspicious':
        return Icons.gpp_maybe_rounded;
      case 'low':
      case 'safe':
      default:
        return Icons.verified_user_rounded;
    }
  }

  // Visual levels for the category bars
  double _getCategoryProgress(String category) {
    final score = _scan.overallRisk;
    if (_scan.riskLevel.toLowerCase() == 'low' || _scan.riskLevel.toLowerCase() == 'safe') return 0.15;
    
    // Distribute risk categories based on score
    switch (category) {
      case 'OTP Theft':
        return (score * 0.95) / 100;
      case 'Credential Theft':
        return (score * 0.85) / 100;
      case 'Data Theft':
        return (score * 0.90) / 100;
      case 'Screen Control':
      default:
        return (score * 0.75) / 100;
    }
  }

  Color _getCategoryColor(double progress) {
    if (progress <= 0.3) return AppColors.safe;
    if (progress <= 0.7) return AppColors.warning;
    return AppColors.danger;
  }

  String _getCategoryText(double progress) {
    if (progress <= 0.3) return 'Low';
    if (progress <= 0.7) return 'Medium';
    return 'High';
  }

  Future<void> _shareReport() async {
    HapticFeedback.lightImpact();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(_scan.scannedAt);
    
    final StringBuffer reportText = StringBuffer();
    reportText.writeln('🛡️ ScanShield Analysis Report');
    reportText.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');
    reportText.writeln('File Name: ${_scan.fileName}');
    reportText.writeln('File Type: ${_scan.fileType.toUpperCase()}');
    if (_scan.fileType == 'apk') {
      reportText.writeln('Package: ${_scan.packageName ?? 'N/A'}');
    } else {
      reportText.writeln('Pages: ${_scan.pages ?? 'N/A'}');
      reportText.writeln('Encrypted: ${_scan.isEncrypted == true ? 'Yes' : 'No'}');
    }
    reportText.writeln('Date: $formattedDate');
    reportText.writeln('Risk Score: ${_scan.overallRisk}/100');
    reportText.writeln('Risk Level: ${_scan.riskLevel.toUpperCase()}');
    reportText.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    reportText.writeln('Findings:');
    if (_scan.findings.isEmpty) {
      reportText.writeln('• No threats detected ✅');
    } else {
      for (var finding in _scan.findings) {
        reportText.writeln('• $finding');
      }
    }
    
    reportText.writeln('\nRecommendation:');
    reportText.writeln(_scan.recommendation);
    reportText.writeln('\nScanned via ScanShield');

    await Clipboard.setData(ClipboardData(text: reportText.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report summary copied to clipboard!'),
          backgroundColor: AppColors.safe,
        ),
      );
    }
  }

  Future<void> _deleteScan() async {
    if (_scan.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete unsaved scan report.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Delete Report', style: AppTextStyles.headingMedium),
          content: const Text('Are you sure you want to delete this scan report permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _firestoreService.deleteScan(_scan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan report deleted successfully.'),
              backgroundColor: AppColors.safe,
            ),
          );
          Navigator.pop(context); // Go back
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete report: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(_scan.scannedAt);
    final isApk = _scan.fileType == 'apk';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Report',
            onPressed: _shareReport,
          ),
          if (_scan.id.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _deleteScan();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 20),
                      SizedBox(width: 8),
                      Text('Delete Report', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isDeleting
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Animated Risk Score Circle
                          RiskScoreCircle(
                            score: _scan.overallRisk,
                            level: _scan.riskLevel,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          // Risk Level Badge Pill
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: _riskColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _riskColor.withAlpha(120), width: 1.5),
                              ),
                              child: Text(
                                _badgeText,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: _riskColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingLarge * 1.5),

                          // Recommendation Card
                          Container(
                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border(
                                left: BorderSide(color: _riskColor, width: 4.5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_recommendationIcon, color: _riskColor, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recommendation',
                                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _scan.recommendation,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingLarge),

                          // Info Card (APK or PDF Specific)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium, vertical: 8),
                              child: Column(
                                children: [
                                  InfoRowWidget(
                                    icon: isApk ? Icons.android_rounded : Icons.picture_as_pdf_rounded,
                                    label: 'File Name',
                                    value: _scan.fileName,
                                  ),
                                  const Divider(color: AppColors.background, height: 1),
                                  if (isApk) ...[
                                    InfoRowWidget(
                                      icon: Icons.inventory_2_outlined,
                                      label: 'Package',
                                      value: _scan.packageName ?? 'N/A',
                                    ),
                                    const Divider(color: AppColors.background, height: 1),
                                  ] else ...[
                                    InfoRowWidget(
                                      icon: Icons.pages_rounded,
                                      label: 'Pages',
                                      value: _scan.pages?.toString() ?? 'N/A',
                                    ),
                                    const Divider(color: AppColors.background, height: 1),
                                    InfoRowWidget(
                                      icon: Icons.lock_outline_rounded,
                                      label: 'Encrypted',
                                      value: _scan.isEncrypted == true ? 'Yes' : 'No',
                                    ),
                                    const Divider(color: AppColors.background, height: 1),
                                  ],
                                  InfoRowWidget(
                                    icon: Icons.calendar_month_outlined,
                                    label: 'Scanned',
                                    value: formattedDate.split(' - ').first,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingLarge * 1.5),

                          // PDF Specific Metadata Section
                          if (!isApk && _scan.metadata != null && _scan.metadata!.isNotEmpty) ...[
                            SectionHeader(title: '📄 PDF Metadata'),
                            const SizedBox(height: AppSizes.paddingMedium),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium, vertical: 8),
                                child: Column(
                                  children: [
                                    InfoRowWidget(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Author',
                                      value: _scan.metadata?['author']?.toString() ?? 'N/A',
                                    ),
                                    const Divider(color: AppColors.background, height: 1),
                                    InfoRowWidget(
                                      icon: Icons.computer_rounded,
                                      label: 'Creator',
                                      value: _scan.metadata?['creator']?.toString() ?? 'N/A',
                                    ),
                                    const Divider(color: AppColors.background, height: 1),
                                    InfoRowWidget(
                                      icon: Icons.settings_applications_outlined,
                                      label: 'Producer',
                                      value: _scan.metadata?['producer']?.toString() ?? 'N/A',
                                    ),
                                    const Divider(color: AppColors.background, height: 1),
                                    InfoRowWidget(
                                      icon: Icons.title_rounded,
                                      label: 'Title',
                                      value: _scan.metadata?['title']?.toString() ?? 'N/A',
                                    ),
                                    const Divider(color: AppColors.background, height: 1),
                                    InfoRowWidget(
                                      icon: Icons.subject_rounded,
                                      label: 'Subject',
                                      value: _scan.metadata?['subject']?.toString() ?? 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingLarge * 1.5),
                          ],

                          // Threat Categories Section (Visual)
                          SectionHeader(title: '🛡️ Threat Categories'),
                          const SizedBox(height: AppSizes.paddingMedium),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.paddingMedium),
                              child: Column(
                                children: [
                                  _buildCategoryProgressItem('OTP Theft', Icons.sms_failed_rounded),
                                  const SizedBox(height: 16),
                                  _buildCategoryProgressItem('Credential Theft', Icons.password_rounded),
                                  const SizedBox(height: 16),
                                  _buildCategoryProgressItem('Data Theft', Icons.cloud_off_rounded),
                                  const SizedBox(height: 16),
                                  _buildCategoryProgressItem('Screen Control', Icons.screen_share_rounded),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingLarge * 1.5),

                          // Findings Section
                          SectionHeader(
                            title: '🔍 Detected Findings',
                            count: _scan.findings.isEmpty ? null : _scan.findings.length,
                            badgeColor: AppColors.danger,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),
                          if (_scan.findings.isEmpty)
                            _buildEmptyState('No issues detected ✅')
                          else
                            Column(
                              children: _scan.findings
                                  .map(
                                    (finding) => Card(
                                      color: AppColors.surface,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                finding,
                                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: AppSizes.paddingLarge * 1.5),

                          // Permissions Section (APK only)
                          if (isApk) ...[
                            SectionHeader(
                              title: '🔐 Permissions Detected',
                              count: _scan.permissionsDetected.isEmpty ? null : _scan.permissionsDetected.length,
                              badgeColor: AppColors.primary,
                            ),
                            const SizedBox(height: AppSizes.paddingMedium),
                            if (_scan.permissionsDetected.isEmpty)
                              _buildEmptyState('No permissions requested')
                            else
                              Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                children: _scan.permissionsDetected
                                    .map((perm) => PermissionChip(permission: perm))
                                    .toList(),
                              ),
                            const SizedBox(height: AppSizes.paddingLarge * 1.5),
                          ],

                          // Suspicious APIs Section (APK only)
                          if (isApk) ...[
                            SectionHeader(
                              title: '⚠️ Suspicious APIs',
                              count: _scan.suspiciousApis.isEmpty ? null : _scan.suspiciousApis.length,
                              badgeColor: AppColors.warning,
                            ),
                            const SizedBox(height: AppSizes.paddingMedium),
                            if (_scan.suspiciousApis.isEmpty)
                              _buildEmptyState('No suspicious APIs found')
                            else
                              Column(
                                children: _scan.suspiciousApis
                                    .map(
                                      (api) => Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.code_rounded, color: AppColors.warning, size: 18),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SelectableText(
                                                  api,
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: AppSizes.paddingLarge),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _shareReport,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy Text Summary'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.shield_outlined, size: 18),
                          label: const Text('Scan Another APK'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCategoryProgressItem(String category, IconData icon) {
    final progress = _getCategoryProgress(category);
    final color = _getCategoryColor(progress);
    final levelText = _getCategoryText(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              category,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              levelText,
              style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
