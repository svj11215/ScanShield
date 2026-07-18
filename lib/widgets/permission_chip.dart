import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';
import '../utils/permission_descriptions.dart';

class PermissionChip extends StatelessWidget {
  final String permission;

  const PermissionChip({
    super.key,
    required this.permission,
  });

  void _showDetailsDialog(BuildContext context) {
    final cleanName = permission.replaceAll('android.permission.', '');
    final description = getPermissionDescription(permission);
    final isDangerous = isDangerousPermission(permission);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(
                isDangerous ? Icons.gpp_maybe_rounded : Icons.info_outline_rounded,
                color: isDangerous ? AppColors.danger : AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cleanName,
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDangerous ? AppColors.danger : AppColors.textSecondary).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDangerous ? 'DANGEROUS PERMISSION' : 'NORMAL PERMISSION',
                  style: AppTextStyles.caption.copyWith(
                    color: isDangerous ? AppColors.danger : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDangerous = isDangerousPermission(permission);
    final chipColor = isDangerous ? AppColors.danger : AppColors.surface;
    final textColor = AppColors.textPrimary;
    final cleanName = permission.replaceAll('android.permission.', '');

    return GestureDetector(
      onTap: () => _showDetailsDialog(context),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor.withAlpha(isDangerous ? 35 : 100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDangerous ? AppColors.danger.withAlpha(100) : AppColors.surface.withAlpha(200),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDangerous ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: isDangerous ? AppColors.danger : AppColors.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                cleanName,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
