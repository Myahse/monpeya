import 'package:flutter/material.dart';

class SimPalette {
  const SimPalette({
    required this.isDark,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.onPrimary,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.danger,
  });

  final bool isDark;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color onPrimary;
  final Color bg;
  final Color surface;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color danger;

  static const light = SimPalette(
    isDark: false,
    primary: SimBrand.primary,
    primaryDark: SimBrand.primaryDark,
    primarySoft: SimBrand.soft,
    onPrimary: Colors.white,
    bg: Color(0xFFF5F7F6),
    surface: Color(0xFFF8F8F8),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    danger: Color(0xFFDC2626),
  );

  static SimPalette of(BuildContext context) {
    final platform = MediaQuery.maybePlatformBrightnessOf(context);
    final isDark = platform != null
        ? platform == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;
    return isDark ? light : light;
  }
}

abstract final class SimBrand {
  // SIM Assurances charter. Placeholder navy until SIM's official colours
  // and logo are provided — change them here only.
  static const primary = Color(0xFF0F3D6E);
  static const primaryDark = Color(0xFF0A2A4D);
  static const gradientTop = primary;
  static const gradientBottom = primaryDark;

  /// SIM logo asset (e.g. 'packages/sim/assets/logo/sim.png'); null shows
  /// the name in a badge.
  static const String? logoAsset = null;

  static const background = Color(0xFFF4F6FA);
  static const muted = Color(0xFF4B5563);
  static const border = Color(0xFFE6EAF1);
  static const soft = Color(0xFFEEF3FA);
  static const onPrimary = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const title = 'SIM Assurances';
  static const subtitle = 'RelaxMoto · RelaxAuto · Accidents';

  static const gradient = LinearGradient(
    colors: [gradientTop, gradientBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static SimPalette of(BuildContext context) => SimPalette.of(context);

  static ThemeData moduleTheme(BuildContext context) {
    final b = of(context);
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light, fontFamily: 'Urbanist');
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: b.primary, brightness: Brightness.light),
      scaffoldBackgroundColor: b.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: b.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: b.primary,
          foregroundColor: b.onPrimary,
        ),
      ),
    );
  }
}

class SimTheme extends StatelessWidget {
  const SimTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(data: SimBrand.moduleTheme(context), child: child);
  }
}
