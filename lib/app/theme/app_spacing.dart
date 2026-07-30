import 'package:flutter/material.dart';

abstract class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

abstract class AppRadii {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double pill = 100.0;
  static const double full = 999.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));
}

abstract class AppShadows {
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: const Color(0xFF1E2116).withValues(alpha: 0.05),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> medium = [
    BoxShadow(
      color: const Color(0xFF1E2116).withValues(alpha: 0.08),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
  ];

  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF1E2116).withValues(alpha: 0.12),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> floatingNav = [
    BoxShadow(
      color: const Color(0xFF1E2116).withValues(alpha: 0.14),
      blurRadius: 32,
      spreadRadius: 2,
      offset: const Offset(0, 12),
    ),
  ];
}
