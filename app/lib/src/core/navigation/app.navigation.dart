import 'package:flutter/material.dart';

/// Shared back navigation for non-auth screens.
class AppNavigation {
  AppNavigation._();

  static void pop(BuildContext context, [Object? result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }
}
