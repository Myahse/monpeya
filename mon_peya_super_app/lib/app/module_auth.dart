import 'package:flutter/material.dart';

import 'routing/routes.dart';
import 'storage/auth_store.dart';

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
