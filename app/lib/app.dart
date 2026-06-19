import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/src/core/system/system_ui.config.dart';
import 'package:app/src/integration/adapters/billetterie_host.adapter.dart';
import 'package:app/src/integration/adapters/immo_host.adapter.dart';
import 'package:app/src/integration/adapters/leadway_host.adapter.dart';
import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';
import 'package:app/src/core/routing/routes.dart';

void _registerModuleHosts() {
  MonPeyaPeyapayHostAdapter.register();
  MonPeyaImmoHostAdapter.register();
  MonPeyaBilletterieHostAdapter.register();
  MonPeyaLeadwayHostAdapter.register();
}

class MonPeyaSuperApp extends StatefulWidget {
  const MonPeyaSuperApp({super.key});

  @override
  State<MonPeyaSuperApp> createState() => _MonPeyaSuperAppState();
}

class _MonPeyaSuperAppState extends State<MonPeyaSuperApp> {
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
        final brightness = Theme.of(context).brightness;
        final overlay = monPeyaSystemUiOverlay(brightness);

        // Fixed app typography: ignore OS display/font size (accessibility text scale).
        final fixedMedia = media.copyWith(
          textScaler: const TextScaler.linear(_textScale),
          boldText: false,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: MediaQuery(data: fixedMedia, child: childWidget),
        );
      },
      navigatorKey: rootNavKey,
      initialRoute: Routes.splash,
      routes: buildRoutes(),
    );
  }
}
