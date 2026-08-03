import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';

/// Spacing + brand green. Surfaces/text resolve from device light/dark via [of].
abstract final class RentalTheme {
  static const green = ImmoBrand.rentalGreen;
  static const greenDark = green;
  static const greenMid = green;
  static const greenCta = green;
  static const greenAccent = green;
  static const greenAccentDark = green;

  /// Adaptive palette for the current brightness.
  static ImmoRentalPalette of(BuildContext context) =>
      ImmoBrand.rentalOf(context);

  static ImmoRentalPalette paletteOf(BuildContext context) => of(context);

  // Legacy fixed light tokens — prefer [of] for new UI.
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const surface = Color(0xFFF7F8F7);
  static const sheetWhite = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE5E7EB);
  static const borderGray = Color(0xFFE5E7EB);
  static const searchBg = Color(0xFFF3F4F6);

  static const bottomNavHeight = 72.0;
  static const bottomNavSafe = 12.0;
  static const scrollBottomPad = 96.0;

  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;
  static const spacingXxl = 48.0;

  static const headerGradient = LinearGradient(
    colors: [green, green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const ctaGradient = LinearGradient(
    colors: [green, green],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const addTenantGradient = LinearGradient(
    colors: [green, green],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const modalCancelGradient = LinearGradient(
    colors: [green, green],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
