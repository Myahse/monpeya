import 'package:flutter/material.dart';
import 'package:immo/immo.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/peyapay/peyapay_profile.util.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';


class MonPeyaImmoHostAdapter implements ImmoHostAuth {
  const MonPeyaImmoHostAdapter();

  static void register() {
    ImmoHostBridge.auth = const MonPeyaImmoHostAdapter();
    ImmoHostBridge.onExitModule = _exitToMonPeyaHome;
    ImmoHostBridge.ensureSession = ModuleAuth.ensureRegistered;
    ImmoHostBridge.resolveBusinessOnlyAccount = AuthStore.requiresBusinessServiceUi;
    ImmoHostBridge.sessionChanges = MonPeyaSession.instance;
  }

  static void _exitToMonPeyaHome(BuildContext context) {
    AppStackScope.maybeOf(context)?.exitModule();
  }

  @override
  Future<bool> isRegistered() => AuthStore.hasAccount();

  @override
  Future<bool> isSessionActive() => ModuleAuth.hasActiveSessionOrToken();

  @override
  Future<String?> displayName() async {
    if (!await ModuleAuth.hasActiveSessionOrToken()) return null;
    final name = PeyapayProfileDisplay.clientName();
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final phone = await AuthStore.getPhone();
    if (phone != null && phone.trim().isNotEmpty) {
      return PeyapayProfileDisplay.formatPhone(phone);
    }
    return null;
  }

  @override
  Future<String?> authToken() => AuthStore.immoAuthToken();

  @override
  Future<String?> getPhone() => AuthStore.getPhone();

  @override
  Future<String?> getPinForPhone(String phone) => AuthStore.getPinForPhone(phone);

  @override
  Future<String?> immoUserId() => AuthStore.immoUserId();

  @override
  Future<void> setAuthToken(String? token) => AuthStore.setImmoAuthToken(token);

  @override
  Future<void> setImmoUserId(String? userId) => AuthStore.setImmoUserId(userId);
}
