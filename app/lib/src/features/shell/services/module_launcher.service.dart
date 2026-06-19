import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/shell/scopes/main_tabs.scope.dart';
import 'package:app/src/features/shell/widgets/main_tabs.shell.dart';

/// Opens a service from the home grid or "Mon espace personnel".
class ModuleLauncher {
  ModuleLauncher._();

  static Future<void> open(BuildContext context, AppModule module) async {
    if (module.moduleKey == 'peyapay') {
      _popOverlayRouteIfNeeded(context);
      await MainTabsScope.maybeOf(context)?.call(MainTab.peyapay);
      return;
    }

    _popOverlayRouteIfNeeded(context);
    AppStackScope.maybeOf(context)?.openModule(module);
  }

  static void _popOverlayRouteIfNeeded(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
