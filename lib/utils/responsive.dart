import 'package:flutter/material.dart';

/// Responsive helpers and shared breakpoints used across the app.
///
/// Breakpoints used:
/// - Mobile: width < 600
/// - Tablet: 600 <= width < 1024
/// - Desktop: width >= 1024
class Responsive {
  static const int mobileMax = 599;
  static const int tabletMax = 1023;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= (mobileMax + 1) && w <= tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isCompactMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= 380;

  /// Keeps the existing type hierarchy while preventing fixed text styles
  /// from crowding narrow screens.
  static double textScaleFactor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 380) return 0.88;
    if (width <= mobileMax) return 0.94;
    if (width <= tabletMax) return 0.98;
    return 1;
  }

  static double spacing(BuildContext context, {double desktop = 24}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return desktop * 0.8;
    return desktop * 0.6;
  }

  static EdgeInsets cardPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(14);
    return const EdgeInsets.all(12);
  }

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity;
  }

  static EdgeInsets adaptivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  }

  static double buttonHeight(BuildContext context) {
    if (isDesktop(context)) return 56;
    if (isTablet(context)) return 48;
    return 44;
  }

  static double borderRadius(BuildContext context) {
    if (isDesktop(context)) return 16;
    if (isTablet(context)) return 14;
    return 12;
  }
}
