import 'package:flutter/material.dart';

abstract class ResponsiveBreakpoints {
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < ResponsiveBreakpoints.mobileMax;
  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.mobileMax &&
      screenWidth < ResponsiveBreakpoints.tabletMax;
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.tabletMax;

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMax && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobileMax && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
