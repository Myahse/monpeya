import 'package:flutter/material.dart';

import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/auth.store.dart';

/// Ensures the user is signed in to Mon Peya before opening a native service module.
class ModuleAuth {
  ModuleAuth._();

  static Future<bool> ensureRegistered(BuildContext context) async {
    final ok = await AuthStore.isRegistered();
    if (ok || !context.mounted) return ok;
    await rootNavKey.currentState?.pushNamed(Routes.phoneInput);
    return AuthStore.isRegistered();
  }
}
