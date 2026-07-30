import 'package:flutter/material.dart';

/// Borrowly Design System — Master Visual Identity Color Palette
abstract class AppColors {
  // Brand Header & Dark Accent
  static const Color headerDark = Color(0xFF1E2116);
  static const Color darkBackground = Color(0xFF1E2116);
  static const Color darkSurface = Color(0xFF282C20);
  static const Color darkSurfaceSubtle = Color(0xFF333829);
  static const Color darkBorder = Color(0xFF3E4433);

  // Primary Palette — Warm Camel & Earthy Tan
  static const Color primary = Color(0xFF99744A);
  static const Color primaryDark = Color(0xFF856138);
  static const Color primaryLight = Color(0xFFC28B2C);
  static const Color accent = Color(0xFFDBC2A6);

  // Olive & Earth Tones
  static const Color olive = Color(0xFF414A37);
  static const Color oliveLight = Color(0xFF56634A);
  static const Color sage = Color(0xFF7A876E);

  // Background & Surfaces (Warm Cream & Sand Tones)
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF5F0E6);
  static const Color surfaceSubtle = Color(0xFFE5DBC7);
  static const Color border = Color(0xFFE2DACD);
  static const Color borderSubtle = Color(0xFFEEE7DC);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E2116);
  static const Color textSecondary = Color(0xFF414A37);
  static const Color textMuted = Color(0xFF8C867A);

  static const Color darkTextPrimary = Color(0xFFF5F0E6);
  static const Color darkTextSecondary = Color(0xFFDBC2A6);
  static const Color darkTextMuted = Color(0xFFA0A696);

  // Feedback & Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFC28B2C);
  static const Color danger = Color(0xFFC74A4A);
  static const Color info = Color(0xFF414A37);

  // Overlay / Glassmorphism Tones
  static const Color overlay = Color(0x66000000);
  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color shimmerBase = Color(0xFFEBE5DA);
  static const Color shimmerHighlight = Color(0xFFF7F4EE);
}
