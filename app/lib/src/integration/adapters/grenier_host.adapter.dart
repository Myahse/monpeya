import 'package:flutter/material.dart';
import 'package:grenier/grenier.dart';
import 'package:peyapay/peyapay.dart';

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

  /// Signed-in user from the Mon Peya backend; guests get null.
  static Future<GrenierHostProfile?> _profile() async {
    if (!await ModuleAuth.hasActiveSessionOrToken()) return null;
    final phone = await AuthStore.getPhone();
    final api = PeyapayHostBridge.api;
    var state = api?.clientState;
    if (state == null && api != null && phone != null && phone.isNotEmpty) {
      try {
        state = await api.fetchClientState(phone: phone);
      } catch (_) {}
    }

    final name = PeyapayProfileDisplay.clientName() ??
        PeyapayProfileDisplay.formatPhone(phone);
    if (name.trim().isEmpty) return null;
    final code = _clean(state?.codeClient) ?? _clean(await AuthStore.codeClient());
    return GrenierHostProfile(
      fullName: name,
      phone: phone == null || phone.isEmpty
          ? null
          : PeyapayProfileDisplay.formatPhone(phone),
      email: _clean(state?.email),
      clientCode: code,
      country: _country(state?.codePaysResidence),
    );
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty || t == 'null' ? null : t;
  }

  static String? _country(String? code) {
    final c = _clean(code)?.toUpperCase();
    if (c == null) return null;
    return switch (c) {
      'CI' => "Côte d'Ivoire",
      'SN' => 'Sénégal',
      'ML' => 'Mali',
      'BF' => 'Burkina Faso',
      'FR' => 'France',
      _ => c,
    };
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
