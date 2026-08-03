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

  // Display & Headings (Display: 28, H1: 21, H2: 18, H3: 14.5)
  static TextStyle displayLarge(bool isDark) => _fontStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 36 / 28,
        letterSpacing: -0.5,
      );

  static TextStyle headingLarge(bool isDark) => _fontStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 28 / 21,
        letterSpacing: -0.3,
      );

  static TextStyle headingMedium(bool isDark) => _fontStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 24 / 18,
        letterSpacing: -0.2,
      );

  static TextStyle headingSmall(bool isDark) => _fontStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 20 / 14.5,
      );

  // Body Styles (Body Large: 14.5, Body Medium: 13, Body Small: 11)
  static TextStyle bodyLarge(bool isDark) => _fontStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 22 / 14.5,
      );

  static TextStyle bodyMedium(bool isDark) => _fontStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        height: 18 / 13,
      );

  static TextStyle bodySmall(bool isDark) => _fontStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        height: 15 / 11,
      );

  // Special UI Styles
  static TextStyle buttonText(Color color) => _fontStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle labelText(bool isDark) => _fontStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      );

  static TextStyle badgeText(Color color) => _fontStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );
}
