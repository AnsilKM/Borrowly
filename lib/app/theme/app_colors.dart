import 'package:flutter/material.dart';

/// Borrowly Design System — Master Visual Identity Color Palette
/// Option 2: "Scandinavian Sage & Warm Ochre" (Inspired by Notion & Toast)
abstract class AppColors {
  // Brand Header & Dark Accent (Deep Cypress)
  static const Color headerDark = Color(0xFF161E1A);
  static const Color darkBackground = Color(0xFF161E1A);
  static const Color darkSurface = Color(0xFF222D28);
  static const Color darkSurfaceSubtle = Color(0xFF2F3D36);
  static const Color darkBorder = Color(0xFF3C4E46);

  // Primary Palette — Earthy Sage Green & Warm Ochre
  static const Color primary = Color(0xFF2E5A44);
  static const Color primaryDark = Color(0xFF1E3E2F);
  static const Color primaryLight = Color(0xFF447C60);
  static const Color accent = Color(0xFFE6A15C);

  // Secondary & Accents
  static const Color olive = Color(0xFF3D634E);
  static const Color oliveLight = Color(0xFF568269);
  static const Color sage = Color(0xFFA1C2AE);

  // Background & Surfaces (Warm Eggshell & Natural Linen)
  static const Color background = Color(0xFFF5F2EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFEBE6DC);
  static const Color surfaceSubtle = Color(0xFFDDD6C8);
  static const Color border = Color(0xFFD5CDBE);
  static const Color borderSubtle = Color(0xFFE4DDD0);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C2420);
  static const Color textSecondary = Color(0xFF3D4C44);
  static const Color textMuted = Color(0xFF708076);

  static const Color darkTextPrimary = Color(0xFFF2EFE8);
  static const Color darkTextSecondary = Color(0xFFD1C7B7);
  static const Color darkTextMuted = Color(0xFF93A39A);

  // Feedback & Status Colors
  static const Color success = Color(0xFF2D8A56);
  static const Color warning = Color(0xFFE6A15C);
  static const Color danger = Color(0xFFD9534F);
  static const Color info = Color(0xFF2E5A44);

  // Overlay / Glassmorphism Tones
  static const Color overlay = Color(0x66000000);
  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color shimmerBase = Color(0xFFDDD6C8);
  static const Color shimmerHighlight = Color(0xFFEBE6DC);
}
