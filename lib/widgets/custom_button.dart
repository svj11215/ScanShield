import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    final contentColor = AppColors.textOnPrimary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: contentColor,
          disabledBackgroundColor: themeColor.withAlpha(100),
          disabledForegroundColor: contentColor.withAlpha(150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: contentColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.buttonText.copyWith(color: contentColor),
                  ),
                ],
              ),
      ),
    );
  }
}
