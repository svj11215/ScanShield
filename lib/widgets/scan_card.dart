import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_model.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';
import '../utils/constants.dart';
import 'risk_indicator.dart';

class ScanCard extends StatelessWidget {
  final ScanModel scan;
  final VoidCallback onTap;

  const ScanCard({
    super.key,
    required this.scan,
    required this.onTap,
  });

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Row(
            children: [
              // Icon block based on status
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scan.riskColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  scan.riskLevel.toLowerCase() == 'high' || scan.riskLevel.toLowerCase() == 'malicious'
                      ? Icons.gpp_bad_rounded
                      : scan.riskLevel.toLowerCase() == 'medium' || scan.riskLevel.toLowerCase() == 'suspicious'
                          ? Icons.gpp_maybe_rounded
                          : Icons.verified_user_rounded,
                  color: scan.riskColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),

              // Title, date and indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.fileName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RiskIndicator(
                          riskLevel: scan.riskLevel,
                          riskScore: scan.overallRisk,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(scan.scannedAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action Arrow
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
