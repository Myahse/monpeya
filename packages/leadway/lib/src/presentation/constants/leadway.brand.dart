import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resolved light/dark surface tokens for Leadway screens.
class LeadwayPalette {
  const LeadwayPalette({
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

  static const light = LeadwayPalette(
    isDark: false,
    primary: Color(0xFF006D56),
    primaryDark: Color(0xFF00453B),
    primarySoft: Color(0xFFE8F5E9),
    onPrimary: Colors.white,
    bg: Color(0xFFF5F7F6),
    surface: Color(0xFFF8F8F8),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    danger: Color(0xFFDC2626),
  );

  static const dark = LeadwayPalette(
    isDark: true,
    primary: Color(0xFF2BB673),
    primaryDark: Color(0xFF1B8A56),
    primarySoft: Color(0xFF143D32),
    onPrimary: Colors.white,
    bg: Color(0xFF0F1412),
    surface: Color(0xFF161C19),
    card: Color(0xFF1C2420),
    text: Color(0xFFF1F5F3),
    muted: Color(0xFF9CA3AF),
    border: Color(0xFF2A3330),
    danger: Color(0xFFF87171),
  );

  static LeadwayPalette of(BuildContext context) {
    final platform = MediaQuery.maybePlatformBrightnessOf(context);
    final isDarkMode = platform != null
        ? platform == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? LeadwayPalette.dark : LeadwayPalette.light;
  }
}

/// Leadway Assurance brand tokens (from official logo) + module theme.
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

  static LeadwayPalette of(BuildContext context) => LeadwayPalette.of(context);

  /// Local module theme so inherited Text / icons stay readable on Leadway surfaces.
  static ThemeData moduleTheme(BuildContext context) {
    final b = of(context);
    final brightness = b.isDark ? Brightness.dark : Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Urbanist',
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: b.primary,
      onPrimary: b.onPrimary,
      secondary: b.primaryDark,
      onSecondary: b.onPrimary,
      surface: b.card,
      onSurface: b.text,
      error: b.danger,
      onError: Colors.white,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: b.bg,
      cardColor: b.card,
      dividerColor: b.border,
      primaryColor: b.primary,
      iconTheme: IconThemeData(color: b.text),
      primaryIconTheme: IconThemeData(color: b.onPrimary),
      textTheme: base.textTheme.apply(
        bodyColor: b.text,
        displayColor: b.text,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: b.onPrimary,
        displayColor: b.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: b.bg,
        foregroundColor: b.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle:
            b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: b.text),
        titleTextStyle: TextStyle(
          color: b.text,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: b.card,
        labelStyle: TextStyle(color: b.muted, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: b.muted),
        floatingLabelStyle:
            TextStyle(color: b.primary, fontWeight: FontWeight.w700),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b.primary, width: 1.5),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: b.text, fontWeight: FontWeight.w600),
      ),
      listTileTheme: ListTileThemeData(
        textColor: b.text,
        iconColor: b.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: b.primary,
          foregroundColor: b.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: b.primary,
          foregroundColor: b.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: b.primary,
          side: BorderSide(color: b.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: b.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return b.primary;
          return b.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return b.primary.withValues(alpha: 0.35);
          }
          return b.border;
        }),
      ),
    );
  }
}

/// Wraps Leadway routes so text/icons inherit readable colors.
class LeadwayTheme extends StatelessWidget {
  const LeadwayTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LeadwayBrand.moduleTheme(context),
      child: child,
    );
  }
}
