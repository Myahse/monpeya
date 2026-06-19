import 'package:flutter/material.dart';

/// Leadway Assurance brand tokens (from official logo).
abstract final class LeadwayBrand {
  /// Orange « Assurance » — couleur principale du service.
  static const primary = Color(0xFFE66B27);

  /// Orange dégradé haut (emblème).
  static const gradientTop = Color(0xFFF26522);

  /// Jaune dégradé bas (emblème).
  static const gradientBottom = Color(0xFFFFCB05);

  static const onPrimary = Colors.white;
  static const textDark = Color(0xFF1A1A1A);

  static const gradient = LinearGradient(
    colors: [gradientTop, gradientBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
