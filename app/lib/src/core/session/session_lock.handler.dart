import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app/src/core/auth/auth.navigation.dart';
import 'package:app/src/core/config/mon_peya_env.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/auth/presentation/login_pin/screens/login_pin.screen.dart';
import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';

/// Locks Mon Peya when the app leaves the foreground; phone/PIN stay in [AuthStore].
class SessionLock {
  SessionLock._();

  static var _unlockInFlight = false;

  static const _authRoutes = <String>{
    Routes.splash,
    Routes.onboarding,
    Routes.phoneInput,
    Routes.registrationFlow,
    Routes.loginPin,
  };

  static Future<void> lock() async {
    endMonPeyaSession();
    await AuthStore.endSession();
    notifyMonPeyaSessionChanged();
  }

  static Future<void> promptUnlockIfNeeded(GlobalKey<NavigatorState> navKey) async {
    if (_unlockInFlight) return;
    if (kDebugMode && MonPeyaEnv.skipForcedAuth) return;
    if (MonPeyaSession.instance.isSessionActive) return;
    if (MonPeyaSession.instance.isAuthOverlayVisible) return;
    if (!await AuthStore.hasAccount()) return;

    final nav = navKey.currentState;
    final context = nav?.context;
    if (context == null || !context.mounted) return;

    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null && _authRoutes.contains(routeName)) return;

    _unlockInFlight = true;
    try {
      final phone = await AuthStore.getPhone();
      if (!context.mounted) return;
      await pushFullScreenAuth<bool>(
        context,
        LoginPinScreen(embeddedInModule: true, phoneNumber: phone),
      );
    } finally {
      _unlockInFlight = false;
    }
  }
}
