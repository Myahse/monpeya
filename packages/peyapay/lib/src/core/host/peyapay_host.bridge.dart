import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:peyapay/src/data/services/peyapay_api.service.dart';

typedef PeyapayHostAssetLoader = Future<Uint8List?> Function(String assetPath);


class PeyapayHostRoutes {
  PeyapayHostRoutes._();

  static const phoneInput = '/phone';
  static const settings = '/settings';
}

/// Host-provided Mon Peya session used by Peya Pay and payment flows from services.
abstract class PeyapayHostAuth {
  /// True when the user entered PIN this session (in-memory).
  Future<bool> isSessionActive();


  Future<bool> hasAccount();

  Future<String?> getPhone();

  Future<String?> authToken();
}

typedef PeyapayHostRouteOpener = Future<void> Function(String routeName);

typedef PeyapayHostNewsBuilder = Widget Function(BuildContext context, {double height});

/// Called before a wallet payment, transfer, or deposit is confirmed.
typedef PeyapayHostTransactionGuard = Future<bool> Function(BuildContext context);

/// Registered by Mon Peya before opening Peya Pay.
class PeyapayHostBridge {
  PeyapayHostBridge._();

  static PeyapayHostAuth? auth;
  static PeyapayHostRouteOpener? openRoute;
  static PeyapayHostNewsBuilder? buildNewsCarousel;

  /// Mon Peya shell registers this to require sign-up / PIN before transactions.
  static PeyapayHostTransactionGuard? ensureRegisteredForTransaction;

 
  static Listenable? sessionChanges;

  /// Shared PeyaPay wallet API client (auth, balance, transfers, …).
  static PeyapayApiService? api;

  /// Optional hook for balance/UI refresh after wallet mutations.
  static VoidCallback? onSessionChanged;

  /// Mon Peya shell logo for PDF receipts (`assets/logo/photo-Photoroom.png`).
  static const monPeyaLogoAssetPath = 'assets/logo/photo-Photoroom.png';

  /// Loads host-bundle assets (Mon Peya logos) from the app package.
  static PeyapayHostAssetLoader? loadHostAsset;

  static void notifySessionChanged() => onSessionChanged?.call();

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
