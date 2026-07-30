import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Borrowly Design System — Plus Jakarta Sans Typography Hierarchy
abstract class AppTypography {
  static TextStyle _fontStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double height = 1.3,
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Display & Headings (H1: 32/40 Bold, H2: 24/32 SemiBold, H3: 20/28 SemiBold)
  static TextStyle displayLarge(bool isDark) => _fontStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 40 / 32,
        letterSpacing: -0.6,
      );

  static TextStyle headingLarge(bool isDark) => _fontStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 32 / 24,
        letterSpacing: -0.4,
      );

  static TextStyle headingMedium(bool isDark) => _fontStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 28 / 20,
        letterSpacing: -0.2,
      );

  static TextStyle headingSmall(bool isDark) => _fontStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 24 / 16,
      );

  // Body Styles (Body: 16/24 Regular)
  static TextStyle bodyLarge(bool isDark) => _fontStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 24 / 16,
      );

  static TextStyle bodyMedium(bool isDark) => _fontStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        height: 20 / 14,
      );

  static TextStyle bodySmall(bool isDark) => _fontStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        height: 16 / 12,
      );

  // Special UI Styles
  static TextStyle buttonText(Color color) => _fontStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle labelText(bool isDark) => _fontStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      );

  static TextStyle badgeText(Color color) => _fontStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      );
}
