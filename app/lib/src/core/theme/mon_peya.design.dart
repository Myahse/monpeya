import 'package:flutter/material.dart';

/// Mon Peya design tokens — one source for colours, radii, spacing and
/// motion so the shell and every module feel like the same app.
abstract final class MonPeyaColors {
  /// Brand green (Peya Pay, primary actions).
  static const green = Color(0xFF006D56);

  /// Deep green used for hero gradients and headers.
  static const greenDeep = Color(0xFF063E1C);

  /// Bright accent for highlights (logo figure).
  static const lime = Color(0xFF34C759);

  static const danger = Color(0xFFFF5252);

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF00876A), green, greenDeep],
    stops: [0, 0.45, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF4F6F9);

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : Colors.white;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE9ECEF);

  /// Accent per service so tiles, headers and module chrome match.
  static Color moduleAccent(String? moduleKey) {
    final k = (moduleKey ?? '').toLowerCase();
    if (k.contains('peyapay')) return green;
    if (k == 'real-estate' || k.contains('rental')) return const Color(0xFF063E1C);
    if (k.contains('construction')) return const Color(0xFFFF9401);
    if (k.contains('collection')) return const Color(0xFF006D56);
    if (k.contains('sim')) return const Color(0xFF0E7C66);
    if (k.contains('leadway')) return const Color(0xFFF57C00);
    if (k.contains('billetterie-transport')) return const Color(0xFF0EA5E9);
    if (k.contains('billetterie')) return const Color(0xFF7C3AED);
    if (k.contains('grenier')) return const Color(0xFF65A30D);
    return green;
  }
}

abstract final class MonPeyaRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class MonPeyaMotion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const curve = Curves.easeOutCubic;
}

/// Card decoration shared by home, settings and module hubs.
BoxDecoration monPeyaCard(BuildContext context, {double radius = MonPeyaRadius.md}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: MonPeyaColors.surface(context),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: MonPeyaColors.border(context)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.3 : 0.05),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
