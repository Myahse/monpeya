import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

/// Shared light/dark surfaces for Billetterie Événements screens.
class EventUiChrome {
  const EventUiChrome({
    required this.isLight,
    required this.brand,
    required this.scaffold,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.hairline,
    required this.searchFill,
    required this.chipIdle,
    required this.chipIdleBorder,
    required this.chipIdleFg,
    required this.chipSelectedFg,
    required this.iconOnSurface,
    required this.handle,
    required this.statusStyle,
    required this.wheelStage,
    required this.wheelDateTrack,
    required this.wheelTimeTrack,
    required this.wheelRim,
    required this.wheelCardIdle,
    required this.wheelSelectedBg,
    required this.wheelSelectedFg,
    required this.wheelIdleFg,
    required this.wheelHub,
    required this.wheelAccent,
  });

  factory EventUiChrome.of(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    // Prefer device brightness so Event home tracks the phone theme
    // even if a parent Theme is stale / mismatched.
    final isLight =
        MediaQuery.platformBrightnessOf(context) == Brightness.light;

    if (isLight) {
      return EventUiChrome(
        isLight: true,
        brand: brand,
        scaffold: brand.bg,
        surface: brand.surface,
        card: brand.card,
        text: brand.text,
        muted: brand.muted,
        border: brand.border,
        hairline: brand.border,
        searchFill: Colors.white,
        chipIdle: Colors.white,
        chipIdleBorder: brand.border,
        chipIdleFg: brand.muted,
        chipSelectedFg: Colors.white,
        iconOnSurface: brand.text,
        handle: brand.border,
        statusStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        wheelStage: brand.bg,
        wheelDateTrack: const Color(0xFFF1F5F9),
        wheelTimeTrack: const Color(0xFFE8E4F5),
        wheelRim: brand.border,
        wheelCardIdle: const Color(0xFFE2E8F0),
        wheelSelectedBg: Colors.white,
        wheelSelectedFg: brand.text,
        wheelIdleFg: brand.muted,
        wheelHub: const Color(0xFFF8FAFC),
        wheelAccent: brand.primary,
      );
    }

    return EventUiChrome(
      isLight: false,
      brand: brand,
      scaffold: Colors.black,
      surface: const Color(0xFF1A1A1E),
      card: const Color(0xFF1A1A1E),
      text: Colors.white,
      muted: Colors.white.withValues(alpha: 0.55),
      border: Colors.white24,
      hairline: const Color(0xFF2A2A2E),
      searchFill: const Color(0xFF1A1A1E),
      chipIdle: const Color(0xFF1A1A1E),
      chipIdleBorder: Colors.white12,
      chipIdleFg: Colors.white.withValues(alpha: 0.55),
      chipSelectedFg: Colors.white,
      iconOnSurface: Colors.white,
      handle: Colors.white24,
      statusStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      wheelStage: const Color(0xFF141416),
      wheelDateTrack: const Color(0xFF1C1C20),
      wheelTimeTrack: const Color(0xFF25252B),
      wheelRim: const Color(0xFF3A3A42),
      wheelCardIdle: const Color(0xFF2A2A2E),
      wheelSelectedBg: Colors.white,
      wheelSelectedFg: const Color(0xFF1A1A1E),
      wheelIdleFg: const Color(0xFF9CA3AF),
      wheelHub: const Color(0xFF101014),
      wheelAccent: const Color(0xFFB8B4FF),
    );
  }

  final bool isLight;
  final BilletterieBrand brand;
  final Color scaffold;
  final Color surface;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color hairline;
  final Color searchFill;
  final Color chipIdle;
  final Color chipIdleBorder;
  final Color chipIdleFg;
  final Color chipSelectedFg;
  final Color iconOnSurface;
  final Color handle;
  final SystemUiOverlayStyle statusStyle;

  final Color wheelStage;
  final Color wheelDateTrack;
  final Color wheelTimeTrack;
  final Color wheelRim;
  final Color wheelCardIdle;
  final Color wheelSelectedBg;
  final Color wheelSelectedFg;
  final Color wheelIdleFg;
  final Color wheelHub;
  final Color wheelAccent;

  Color get accent => brand.primaryDark;
}
