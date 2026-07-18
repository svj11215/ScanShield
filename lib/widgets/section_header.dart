import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? badgeColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppColors.primary).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (badgeColor ?? AppColors.primary).withAlpha(80)),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                color: badgeColor ?? AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
