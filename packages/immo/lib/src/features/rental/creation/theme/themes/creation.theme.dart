import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';

/// Adaptive creation-flow palette — maps [ImmoRentalPalette] for light/dark.
class CreationPalette {
  const CreationPalette({required this.rental});

  final ImmoRentalPalette rental;

  bool get isDark => rental.isDark;

  Color get bg => rental.bg;
  Color get card => rental.card;
  Color get textPrimary => rental.text;
  Color get textSecondary => rental.muted;
  Color get textMuted =>
      isDark ? rental.muted.withValues(alpha: 0.75) : const Color(0xFF9E9E9E);
  Color get border => rental.border;
  Color get borderInput => rental.border;
  Color get surfaceMuted => rental.searchFill;
  Color get uploadBg => isDark ? rental.searchFill : const Color(0xFFFAFAFA);
  Color get error => rental.danger;
  Color get disabled => isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC);
  Color get primary => rental.primary;

  /// Subtle green tint for map placeholders, icon badges, success chips.
  Color get greenTint => primary.withValues(alpha: isDark ? 0.2 : 0.12);

  /// Save-exit header divider.
  Color get headerBorder => rental.border;

  static CreationPalette of(BuildContext context) =>
      CreationPalette(rental: ImmoBrand.rentalOf(context));
}

/// Creation flows — greens match home header ([ImmoBrand.rentalGreen]).
abstract final class CreationTheme {
  /// Adaptive palette for the current device brightness.
  static CreationPalette of(BuildContext context) => CreationPalette.of(context);

  static const listingGreen = ImmoBrand.rentalGreen;
  static const tenantGreen = ImmoBrand.rentalGreen;
  static const tenantGreenDark = ImmoBrand.rentalGreen;

  // Legacy fixed light tokens — prefer [of] for new UI.
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
    colors: [tenantGreen, tenantGreen],
  );
}
