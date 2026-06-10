import 'package:flutter/material.dart';

/// Shell route names forwarded through [PeyapayHostBridge.openRoute].
class PeyapayHostRoutes {
  PeyapayHostRoutes._();

  static const phoneInput = '/phone';
  static const settings = '/settings';
}

/// Host-provided Mon Peya session used by Peya Pay and payment flows from services.
abstract class PeyapayHostAuth {
  /// True when the user entered PIN this session (in-memory).
  Future<bool> isSessionActive();

  /// True when phone + PIN are stored on device (registered account).
  Future<bool> hasAccount();

  Future<String?> getPhone();

  Future<String?> authToken();
}

typedef PeyapayHostRouteOpener = Future<void> Function(String routeName);

typedef PeyapayHostNewsBuilder = Widget Function(BuildContext context, {double height});

/// Registered by Mon Peya before opening Peya Pay.
class PeyapayHostBridge {
  PeyapayHostBridge._();

  static PeyapayHostAuth? auth;
  static PeyapayHostRouteOpener? openRoute;
  static PeyapayHostNewsBuilder? buildNewsCarousel;

  /// Fired when Mon Peya login / logout changes (shell registers this).
  static Listenable? sessionChanges;

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
