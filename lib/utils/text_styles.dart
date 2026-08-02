import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Centralized text styles using Inter font family.
/// 
/// For most cases, use `Theme.of(context).textTheme.*` directly.
/// These static getters exist for backward compatibility and convenience
/// in places where BuildContext is not readily available.
class AppTextStyles {
  AppTextStyles._();

  // ─── Display / Headlines ───

  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // ─── Titles ───

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
    height: 1.4,
  );

  // ─── Body ───

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ─── Labels & Captions ───

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );

  // ─── Button ───

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: -0.1,
  );
}
