import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
