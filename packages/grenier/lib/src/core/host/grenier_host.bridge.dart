import 'package:flutter/material.dart';

typedef GrenierHostExitHandler = void Function(BuildContext context);
typedef GrenierEnsureSession = Future<bool> Function(BuildContext context);

class GrenierHostBridge {
  GrenierHostBridge._();

  static GrenierHostExitHandler? onExitModule;
  static GrenierEnsureSession? ensureSession;

  static Future<bool> ensureLoggedIn(BuildContext context) async {
    final handler = ensureSession;
    if (handler == null) return true;
    return handler(context);
  }

  static void exitModule(BuildContext context) {
    final handler = onExitModule;
    if (handler != null) {
      handler(context);
      return;
    }
    Navigator.of(context).maybePop();
  }
}
