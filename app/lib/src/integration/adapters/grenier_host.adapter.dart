import 'package:flutter/material.dart';
import 'package:grenier/grenier.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

class MonPeyaGrenierHostAdapter {
  MonPeyaGrenierHostAdapter._();

  static void register() {
    GrenierHostBridge.onExitModule = _exitToMonPeyaHome;
    GrenierHostBridge.ensureSession = ModuleAuth.ensureRegistered;
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
