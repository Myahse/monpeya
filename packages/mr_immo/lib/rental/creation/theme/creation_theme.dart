import 'package:flutter/material.dart';

/// Creation flows — matches rental-app listing (`#0C5429`) & tenant (`#006F09`) palettes.
abstract final class CreationTheme {
  static const listingGreen = Color(0xFF0C5429);
  static const tenantGreen = Color(0xFF006F09);
  static const tenantGreenDark = Color(0xFF005507);

  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9E9E9E);
  static const border = Color(0xFFE0E0E0);
  static const borderInput = Color(0xFFD1D5DB);
  static const surfaceMuted = Color(0xFFF5F5F5);
  static const uploadBg = Color(0xFFFAFAFA);
  static const error = Color(0xFFEF4444);
  static const disabled = Color(0xFFCCCCCC);

  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  static const listingCtaGradient = LinearGradient(
    colors: [listingGreen, listingGreen],
  );

  static const tenantCtaGradient = LinearGradient(
    colors: [tenantGreen, tenantGreenDark],
  );
}
