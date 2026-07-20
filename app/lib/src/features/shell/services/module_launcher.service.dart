import 'package:flutter/material.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/shell/scopes/main_tabs.scope.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';
import 'package:app/src/features/shell/widgets/main_tabs.shell.dart';

/// Opens a service from the home grid or "Mon espace personnel".
class ModuleLauncher {
  ModuleLauncher._();

  static Future<void> open(BuildContext context, AppModule module) async {
    if (module.moduleKey == 'peyapay') {
      final ok = await ModuleAuth.ensureRegistered(context);
      if (!ok || !context.mounted) return;
      await MainTabsScope.maybeOf(context)?.call(MainTab.peyapay);
      return;
    }

    if (!context.mounted) return;
    AppStackScope.maybeOf(context)?.openModule(module);
  }

  static Future<void> openLeadwayAssurance(BuildContext context) async {
    AppStackScope.maybeOf(context)?.openService(AppStackRoute.leadwayAssurance);
  }
}
