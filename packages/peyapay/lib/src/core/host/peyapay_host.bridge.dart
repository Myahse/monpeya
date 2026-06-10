import 'package:flutter/material.dart';

/// Shell route names forwarded through [PeyapayHostBridge.openRoute].
class PeyapayHostRoutes {
  PeyapayHostRoutes._();

  static const phoneInput = '/phone';
  static const settings = '/settings';
}

/// Host-provided session and navigation from Mon Peya shell.
abstract class PeyapayHostAuth {
  Future<bool> isRegistered();
}

typedef PeyapayHostRouteOpener = Future<void> Function(String routeName);

typedef PeyapayHostNewsBuilder = Widget Function(BuildContext context, {double height});

/// Registered by Mon Peya before opening Peya Pay.
class PeyapayHostBridge {
  PeyapayHostBridge._();

  static PeyapayHostAuth? auth;
  static PeyapayHostRouteOpener? openRoute;
  static PeyapayHostNewsBuilder? buildNewsCarousel;

  static PeyapayHostAuth get requireAuth {
    final host = auth;
    if (host == null) {
      throw StateError('PeyapayHostBridge.auth not configured by Mon Peya shell.');
    }
    return host;
  }

  static Future<void> openNamedRoute(String routeName) async {
    final opener = openRoute;
    if (opener == null) {
      throw StateError('PeyapayHostBridge.openRoute not configured by Mon Peya shell.');
    }
    await opener(routeName);
  }

  static Widget? newsCarousel(BuildContext context, {double height = 200}) {
    return buildNewsCarousel?.call(context, height: height);
  }
}
