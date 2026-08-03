import 'package:flutter/material.dart';

/// Billetterie électronique brand tokens, resolved per theme brightness.
///
/// Use `BilletterieBrand.of(context)` in widgets; it returns the light or
/// dark palette depending on the active [ThemeData.brightness].
class BilletterieBrand {
  const BilletterieBrand({
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.danger,
    required this.onboardingBg,
    required this.navBar,
    required this.searchFill,
    required this.ticketBg,
    required this.ticketDivider,
    required this.ticketLabel,
    required this.ticketInk,
  });

  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color bg;
  final Color surface;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color danger;
  final Color onboardingBg;

  /// Bottom navigation bar background.
  final Color navBar;

  /// Search field fill.
  final Color searchFill;

  /// Ticket card background (white in both themes — tickets stay printed-look).
  final Color ticketBg;

  /// Dashed divider inside the ticket card.
  final Color ticketDivider;

  /// Secondary labels inside the ticket card.
  final Color ticketLabel;

  /// Main text inside the ticket card (dark in both themes, on white).
  final Color ticketInk;

  /// QR codes stay dark-on-white in both themes so they remain scannable.
  static const qrInk = Color(0xFF0F172A);

  static const light = BilletterieBrand(
    primary: Color(0xFF38BDF8),
    primaryDark: Color(0xFF0284C7),
    primarySoft: Color(0xFFE0F2FE),
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    danger: Color(0xFFEF4444),
    onboardingBg: Color(0xFF075985),
    navBar: Color(0xFFF2F2F2),
    searchFill: Color(0xFFE8E8E8),
    ticketBg: Color(0xFFFFFFFF),
    ticketDivider: Color(0xFFD1D5DB),
    ticketLabel: Color(0xFF9CA3AF),
    ticketInk: Color(0xFF0F172A),
  );

  static const dark = BilletterieBrand(
    primary: Color(0xFF38BDF8),
    primaryDark: Color(0xFF0EA5E9),
    primarySoft: Color(0xFF0C4A6E),
    bg: Color(0xFF0F0F0F),
    surface: Color(0xFF1A1A1A),
    card: Color(0xFF1E1E1E),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    border: Color(0xFF2E2E2E),
    danger: Color(0xFFF87171),
    onboardingBg: Color(0xFF075985),
    navBar: Color(0xFF1A1A1A),
    searchFill: Color(0xFF262626),
    // Tickets keep their printed white look even in dark mode.
    ticketBg: Color(0xFFFFFFFF),
    ticketDivider: Color(0xFFD1D5DB),
    ticketLabel: Color(0xFF9CA3AF),
    ticketInk: Color(0xFF0F172A),
  );

  /// Événements — purple accent (distinct from transport sky blue).
  static const eventLight = BilletterieBrand(
    primary: Color(0xFFC084FC),
    primaryDark: Color(0xFF7C3AED),
    primarySoft: Color(0xFFF3E8FF),
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    danger: Color(0xFFEF4444),
    onboardingBg: Color(0xFF5B21B6),
    navBar: Color(0xFFF2F2F2),
    searchFill: Color(0xFFE8E8E8),
    ticketBg: Color(0xFFFFFFFF),
    ticketDivider: Color(0xFFD1D5DB),
    ticketLabel: Color(0xFF9CA3AF),
    ticketInk: Color(0xFF0F172A),
  );

  static const eventDark = BilletterieBrand(
    primary: Color(0xFFC084FC),
    primaryDark: Color(0xFFA78BFA),
    primarySoft: Color(0xFF4C1D95),
    bg: Color(0xFF0F0F0F),
    surface: Color(0xFF1A1A1A),
    card: Color(0xFF1E1E1E),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    border: Color(0xFF2E2E2E),
    danger: Color(0xFFF87171),
    onboardingBg: Color(0xFF5B21B6),
    navBar: Color(0xFF1A1A1A),
    searchFill: Color(0xFF262626),
    ticketBg: Color(0xFFFFFFFF),
    ticketDivider: Color(0xFFD1D5DB),
    ticketLabel: Color(0xFF9CA3AF),
    ticketInk: Color(0xFF0F172A),
  );

  /// Transport (and shared) palette.
  static BilletterieBrand of(BuildContext context) =>
      _isDark(context) ? dark : light;

  /// Événements purple palette.
  static BilletterieBrand eventOf(BuildContext context) =>
      _isDark(context) ? eventDark : eventLight;

  static bool _isDark(BuildContext context) {
    // Device setting first, then Theme — keeps Event/Transport in sync
    // with the phone when ThemeMode.system.
    final platform = MediaQuery.maybePlatformBrightnessOf(context);
    if (platform != null) return platform == Brightness.dark;
    return Theme.of(context).brightness == Brightness.dark;
  }
}
