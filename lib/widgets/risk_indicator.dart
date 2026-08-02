import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';

class RiskIndicator extends StatelessWidget {
  final String riskLevel;
  final int riskScore;

  const RiskIndicator({
    super.key,
    required this.riskLevel,
    required this.riskScore,
  });

  Color get _color {
    switch (riskLevel.toLowerCase()) {
      case 'high':
      case 'malicious':
        return AppColors.danger;
      case 'medium':
      case 'suspicious':
        return AppColors.warning;
      case 'low':
      case 'safe':
      default:
        return AppColors.safe;
    }
  }

  String get _badgeText {
    switch (riskLevel.toLowerCase()) {
      case 'high':
      case 'malicious':
        return 'High 🚨';
      case 'medium':
      case 'suspicious':
        return 'Medium ⚠️';
      case 'low':
      case 'safe':
      default:
        return 'Low ✅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: _color.withAlpha(70),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _badgeText,
            style: AppTextStyles.caption.copyWith(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$riskScore%',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
