import 'package:flutter/material.dart';
import 'package:immo/immo.dart';

import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';


class MonPeyaImmoHostAdapter implements ImmoHostAuth {
  const MonPeyaImmoHostAdapter();

  static void register() {
    ImmoHostBridge.auth = const MonPeyaImmoHostAdapter();
    ImmoHostBridge.onExitModule = _exitToMonPeyaHome;
  }

  static void _exitToMonPeyaHome(BuildContext context) {
    AppStackScope.maybeOf(context)?.exitModule();
  }

  @override
  Future<bool> isRegistered() => AuthStore.hasAccount();

  @override
  Future<bool> isSessionActive() async => MonPeyaSession.instance.isSessionActive;

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
