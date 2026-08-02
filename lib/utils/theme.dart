import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// Color Palette — Premium Light Security Theme
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1B5E7B);       // Deep teal-blue
  static const Color primaryLight = Color(0xFF2980B9);   // Lighter teal-blue
  static const Color secondary = Color(0xFF0D9488);      // Warm teal accent
  static const Color secondaryLight = Color(0xFF14B8A6);  // Lighter teal

  // Semantic
  static const Color danger = Color(0xFFDC2626);         // Error red
  static const Color warning = Color(0xFFD97706);        // Warning amber
  static const Color safe = Color(0xFF16A34A);           // Success green
  static const Color info = Color(0xFF2563EB);           // Info blue

  // Surfaces
  static const Color background = Color(0xFFF8FAFB);    // Cool off-white
  static const Color surface = Color(0xFFFFFFFF);        // Pure white cards
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Subtle gray surface
  static const Color surfaceTint = Color(0xFFEFF6FF);    // Brand-tinted surface

  // Text & Icons
  static const Color textPrimary = Color(0xFF0F172A);    // Near-black slate
  static const Color textSecondary = Color(0xFF64748B);  // Medium gray
  static const Color textTertiary = Color(0xFF94A3B8);   // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White on brand

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);        // Light border
  static const Color borderLight = Color(0xFFF1F5F9);   // Very light border
  static const Color divider = Color(0xFFE2E8F0);       // Divider gray

  // Shadows
  static const Color shadow = Color(0x0A000000);         // Very subtle shadow
  static const Color shadowMedium = Color(0x14000000);   // Medium shadow
}

// ─────────────────────────────────────────────
// Radius Tokens
// ─────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double pill = 50.0;
}

// ─────────────────────────────────────────────
// Theme Definition
// ─────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,

      // ─── Color Scheme ───
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.surfaceTint,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: Color(0xFFCCFBF1),
        onSecondaryContainer: AppColors.secondary,
        tertiary: AppColors.info,
        error: AppColors.danger,
        onError: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        shadow: AppColors.shadow,
      ),

      // ─── App Bar ───
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withAlpha(100),
          disabledForegroundColor: AppColors.textOnPrimary.withAlpha(150),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Input Decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ─── Bottom Navigation Bar ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        dragHandleColor: AppColors.border,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ─── Snackbar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textOnPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: const BorderSide(color: AppColors.border),
        showCheckmark: false,
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ─── Text Theme ───
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
          height: 1.35,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),

      // ─── Popup Menu ───
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),

      // ─── List Tile ───
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),

      // ─── Checkbox ───
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ─── Radio ───
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textTertiary;
        }),
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.borderLight,
        circularTrackColor: AppColors.borderLight,
      ),
    );
  }
}
