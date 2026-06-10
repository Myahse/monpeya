import 'package:flutter/material.dart';

import 'package:app/src/core/auth/auth.navigation.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/auth/presentation/login_pin/screens/login_pin.screen.dart';

/// Ensures the user is registered and signed in before a transaction or payment.
class ModuleAuth {
  ModuleAuth._();

  static Future<bool> ensureRegistered(BuildContext context) async {
    if (MonPeyaSession.instance.isSessionActive) return true;

    if (await AuthStore.hasAccount()) {
      if (!context.mounted) return false;
      final phone = await AuthStore.getPhone();
      if (!context.mounted) return false;
      final ok = await pushFullScreenAuth<bool>(
        context,
        LoginPinScreen(embeddedInModule: true, phoneNumber: phone),
      );
      return ok == true && MonPeyaSession.instance.isSessionActive;
    }

    if (!context.mounted) return false;
    await rootNavKey.currentState?.pushNamed(Routes.phoneInput);
    return MonPeyaSession.instance.isSessionActive;
  }
}
