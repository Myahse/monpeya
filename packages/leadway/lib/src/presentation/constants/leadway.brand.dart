import 'package:flutter/material.dart';

/// Leadway Assurance brand tokens (from official logo).
abstract final class LeadwayBrand {
  /// Vert de la super app — couleur principale du service.
  static const primary = Color(0xFF006D56);

  /// Vert dégradé haut.
  static const gradientTop = Color(0xFF006D56);

  /// Vert dégradé bas.
  static const gradientBottom = Color(0xFF00453B);

  static const onPrimary = Colors.white;
  static const textDark = Color(0xFF1A1A1A);

  static const gradient = LinearGradient(
    colors: [gradientTop, gradientBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
