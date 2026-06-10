import 'package:flutter/material.dart';

import '../modules/adapters/billetterie_host_adapter.dart';
import '../modules/adapters/immo_host_adapter.dart';
import 'routing/routes.dart';

void _registerModuleHosts() {
  MonPeyaImmoHostAdapter.register();
  MonPeyaBilletterieHostAdapter.register();
}

class MonPeyaSuperApp extends StatelessWidget {
  const MonPeyaSuperApp({super.key});

  static const _textScale = 0.90;

  static bool _hostsRegistered = false;

  @override
  Widget build(BuildContext context) {
    if (!_hostsRegistered) {
      _registerModuleHosts();
      _hostsRegistered = true;
    }
    return MaterialApp(
      title: 'Mon Peya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D56),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D56),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final childWidget = child ?? const SizedBox.shrink();

        // Global text size reduction (safe even for styles without explicit fontSize).
        final fixedMedia = media.copyWith(textScaler: const TextScaler.linear(_textScale));

        // IMPORTANT: Do not force a fixed "design size" viewport.
        // That behavior makes the whole app look like it isn't using full width/height.
        return MediaQuery(data: fixedMedia, child: childWidget);
      },
      navigatorKey: rootNavKey,
      initialRoute: Routes.splash,
      routes: buildRoutes(),
    );
  }
}
