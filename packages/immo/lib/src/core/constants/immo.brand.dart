import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mr Immo module branding — adapts to device light/dark (like Billetterie).
abstract final class ImmoBrand {
  /// Canonical Location green — same as the home header.
  static const rentalGreen = Color(0xFF063E1C);

  /// Aliases kept for existing call sites — always [rentalGreen].
  static const rentalPrimary = rentalGreen;
  static const rentalDark = rentalGreen;

  static const constructionPrimary = Color(0xFFFF9401);
  static const constructionDark = Color(0xFFEA580C);

  static const collectionPrimary = Color(0xFF006D56);
  static const collectionDark = Color(0xFF08421F);

  /// Service typeface — Urbanist across Mr Immo Location.
  static String get fontFamily => GoogleFonts.urbanist().fontFamily!;

  static ImmoRentalPalette rentalOf(BuildContext context) =>
      ImmoRentalPalette.of(context);

  /// Module [ThemeData] that follows device brightness.
  static ThemeData rentalModuleTheme(BuildContext context) {
    final b = ImmoRentalPalette.of(context);
    final brightness = b.isDark ? Brightness.dark : Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: b.primary,
      onPrimary: Colors.white,
      secondary: b.primary,
      onSecondary: Colors.white,
      surface: b.card,
      onSurface: b.text,
      error: b.danger,
      onError: Colors.white,
    );

    final urbanist = GoogleFonts.urbanistTextTheme(base.textTheme);
    final urbanistPrimary = GoogleFonts.urbanistTextTheme(base.primaryTextTheme);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: b.bg,
      canvasColor: b.bg,
      cardColor: b.card,
      dividerColor: b.border,
      primaryColor: b.primary,
      iconTheme: IconThemeData(color: b.text),
      primaryIconTheme: const IconThemeData(color: Colors.white),
      textTheme: urbanist.apply(
        bodyColor: b.text,
        displayColor: b.text,
        fontFamily: fontFamily,
      ),
      primaryTextTheme: urbanistPrimary.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
        fontFamily: fontFamily,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: b.bg,
        foregroundColor: b.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle:
            b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: b.text),
        titleTextStyle: GoogleFonts.urbanist(
          color: b.text,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: b.text,
        iconColor: b.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: b.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: b.primary,
          side: BorderSide(color: b.border),
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: b.text,
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: b.primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: b.primary,
        contentTextStyle: GoogleFonts.urbanist(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: b.card,
        titleTextStyle: GoogleFonts.urbanist(
          color: b.text,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: GoogleFonts.urbanist(color: b.muted, fontSize: 14),
      ),
    );
  }
}

/// Location palette — light or dark from device / theme brightness.
class ImmoRentalPalette {
  const ImmoRentalPalette({
    required this.isDark,
    required this.primary,
    required this.primaryDark,
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.searchFill,
    required this.header,
    required this.danger,
  });

  final bool isDark;
  final Color primary;
  final Color primaryDark;
  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color searchFill;
  final Color header;
  final Color danger;

  static const light = ImmoRentalPalette(
    isDark: false,
    primary: ImmoBrand.rentalGreen,
    primaryDark: ImmoBrand.rentalGreen,
    bg: Color(0xFFF7F8F7),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    searchFill: Color(0xFFF3F4F6),
    header: ImmoBrand.rentalGreen,
    danger: Color(0xFFDC2626),
  );

  static const dark = ImmoRentalPalette(
    isDark: true,
    primary: ImmoBrand.rentalGreen,
    primaryDark: ImmoBrand.rentalGreen,
    bg: Color(0xFF0F0F0F),
    card: Color(0xFF1E1E1E),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    border: Color(0xFF2E2E2E),
    searchFill: Color(0xFF262626),
    header: ImmoBrand.rentalGreen,
    danger: Color(0xFFF87171),
  );

  static ImmoRentalPalette of(BuildContext context) =>
      _isDark(context) ? dark : light;

  static bool _isDark(BuildContext context) {
    final platform = MediaQuery.maybePlatformBrightnessOf(context);
    if (platform != null) return platform == Brightness.dark;
    return Theme.of(context).brightness == Brightness.dark;
  }
}

/// Wraps Location routes with a theme that follows device brightness.
class ImmoRentalTheme extends StatelessWidget {
  const ImmoRentalTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ImmoBrand.rentalModuleTheme(context),
      child: child,
    );
  }
}
