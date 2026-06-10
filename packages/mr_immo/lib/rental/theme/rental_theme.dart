import 'package:flutter/material.dart';

/// Design tokens from rental-app React Native (`shared/constants`).
abstract final class RentalTheme {
  static const greenDark = Color(0xFF094420);
  static const greenMid = Color(0xFF126332);
  static const greenCta = Color(0xFF0C5429);
  static const greenAccent = Color(0xFF006F09);
  static const greenAccentDark = Color(0xFF005507);

  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF666666);
  static const surface = Color(0xFFF8F9FA);
  static const sheetWhite = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE0E0E0);
  static const borderGray = Color(0xFFE5E5E5);
  static const searchBg = Color(0xFFF3F4F6);

  static const bottomNavHeight = 100.0;
  static const bottomNavSafe = 20.0;
  static const scrollBottomPad = 120.0;

  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;
  static const spacingXxl = 48.0;

  static const headerGradient = LinearGradient(
    colors: [greenDark, greenMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const ctaGradient = LinearGradient(
    colors: [greenCta, greenCta],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const addTenantGradient = LinearGradient(
    colors: [greenAccent, greenAccentDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const modalCancelGradient = LinearGradient(
    colors: [greenAccent, greenAccentDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
