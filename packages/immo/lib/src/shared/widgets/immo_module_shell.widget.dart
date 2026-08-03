import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/shared/auth/immo_module.session.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';

/// Loading gate + Mon Peya session required screen — no in-module login.
/// Theme follows device light/dark.
class ImmoModuleShell extends StatelessWidget {
  const ImmoModuleShell({
    super.key,
    required this.primaryColor,
    required this.moduleLabel,
    required this.child,
  });

  final Color primaryColor;
  final String moduleLabel;
  final Widget child;

  static bool _isDark(BuildContext context) {
    final platform = MediaQuery.maybePlatformBrightnessOf(context);
    if (platform != null) return platform == Brightness.dark;
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    final dark = _isDark(context);
    final bg = dark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA);
    final text = dark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A1A);
    final muted = dark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final surface = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final base = dark ? ThemeData.dark() : ThemeData.light();
    final urbanist = GoogleFonts.urbanistTextTheme(base.textTheme);

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        fontFamily: GoogleFonts.urbanist().fontFamily,
        colorScheme: ColorScheme(
          brightness: dark ? Brightness.dark : Brightness.light,
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: primaryColor,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: text,
          error: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: bg,
        iconTheme: IconThemeData(color: text),
        textTheme: urbanist.apply(
          bodyColor: text,
          displayColor: text,
          fontFamily: GoogleFonts.urbanist().fontFamily,
        ),
      ),
      child: session.authFailed
          ? _MonPeyaSessionRequired(
              session: session,
              primaryColor: primaryColor,
              moduleLabel: moduleLabel,
              bg: bg,
              text: text,
              muted: muted,
            )
          : child,
    );
  }
}

class _MonPeyaSessionRequired extends StatelessWidget {
  const _MonPeyaSessionRequired({
    required this.session,
    required this.primaryColor,
    required this.moduleLabel,
    required this.bg,
    required this.text,
    required this.muted,
  });

  final ImmoModuleSession session;
  final Color primaryColor;
  final String moduleLabel;
  final Color bg;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => ImmoHostBridge.exitModule(context),
                  icon: Icon(Icons.arrow_back, color: text),
                ),
              ),
              const Spacer(),
              Icon(Icons.phone_android, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Session Mon Peya requise',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                session.error ??
                    'Connectez-vous à Mon Peya, puis rouvrez $moduleLabel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.4),
              ),
              if (session.phone != null) ...[
                const SizedBox(height: 12),
                Text(
                  session.phone!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, color: text),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () => ImmoHostBridge.exitModule(context),
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Retour à Mon Peya'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: session.bootstrap,
                child: Text('Réessayer', style: TextStyle(color: text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
