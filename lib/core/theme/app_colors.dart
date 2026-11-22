import 'package:flutter/material.dart';

class AppColors {
  static const Color paleGold = Color(0xFFC6B283);
  static const Color silk = Color(0xFFDCD0C0);
  static const Color paper = Color(0xFFF4F4F4);
  static const Color charcoal = Color(0xFF373737);
  static const Color darkBackground = Color(0xFF292929);
  static const Color darkSecondary = Color(0xFF49443B);
  static const Color darkBorder = Color(0xFF625744);
  static const Color white = Color(0xFFFFFFFF);

  static const Color primaryDark = charcoal;
  static const Color primary = paleGold;
  static const Color primaryLight = silk;
  static const Color lightGray = paper;
  static const Color mediumGray = silk;
  static const Color textGray = Color(0xFF68645D);
  static const Color textDark = charcoal;
  static const Color success = Color(0xFF66806A);
  static const Color warning = Color(0xFFA17C48);
  static const Color error = Color(0xFFB05E52);
  static const Color info = Color(0xFF6D8290);
  static const Color darkSuccess = Color(0xFFA9C6A7);
  static const Color darkWarning = Color(0xFFDFC18E);
  static const Color darkError = Color(0xFFE29B8F);
  static const Color darkInfo = Color(0xFFA9BFCC);
  static const Color darkSurface = charcoal;
  static const Color darkCard = charcoal;

  static Color kondisiColor(String kondisi, {bool dark = false}) =>
      switch (kondisi) {
        'Sangat Baik' => dark ? darkSuccess : success,
        'Baik' => dark ? silk : textGray,
        'Rusak' => dark ? darkError : error,
        _ => dark ? silk : textGray,
      };
}
