import 'package:flutter/material.dart';
import 'package:grenier/grenier.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/peyapay/peyapay_profile.util.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

class MonPeyaGrenierHostAdapter {
  MonPeyaGrenierHostAdapter._();

  static void register() {
    GrenierHostBridge.onExitModule = _exitToMonPeyaHome;
    GrenierHostBridge.ensureSession = ModuleAuth.ensureRegistered;
    GrenierHostBridge.loadProfile = _profile;
  }

  /// Signed-in user only; guests get null so nothing is shared.
  static Future<GrenierHostProfile?> _profile() async {
    if (!await ModuleAuth.hasActiveSessionOrToken()) return null;
    final phone = await AuthStore.getPhone();
    final name = PeyapayProfileDisplay.clientName() ??
        PeyapayProfileDisplay.formatPhone(phone);
    if (name.trim().isEmpty) return null;
    return GrenierHostProfile(
      fullName: name,
      phone: phone == null || phone.isEmpty
          ? null
          : PeyapayProfileDisplay.formatPhone(phone),
    );
  }

  static void _exitToMonPeyaHome(BuildContext context) {
    final stack = AppStackScope.maybeOf(context);
    if (stack != null) {
      stack.goBack();
      return;
    }
    Navigator.of(context).maybePop();
  }
}
