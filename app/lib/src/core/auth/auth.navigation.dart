import 'package:flutter/material.dart';

import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/session/mon_peya.session.dart';


Future<T?> pushFullScreenAuth<T>(BuildContext context, Widget screen) async {
  MonPeyaSession.instance.beginAuthOverlay();
  try {
    // Always push on the app root navigator so login covers module overlays
    // (Leadway, Immo, etc.) and is not trapped inside a tab navigator.
    final navigator = rootNavKey.currentState;
    if (navigator == null) return null;
    return await navigator.push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (_) => screen,
      ),
    );
  } finally {
    MonPeyaSession.instance.endAuthOverlay();
  }
}

class AuthNavigation {
  AuthNavigation._();

  static void completeAuthFlow(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.app,
      (route) => false,
    );
  }

  static void popUntilApp(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == Routes.app || route.isFirst,
    );
  }

  static void popOrReplace(BuildContext context, String fallbackRoute) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(fallbackRoute);
  }

  static void backFromPhoneInput(BuildContext context, {required bool embeddedInModule}) {
    if (embeddedInModule) {
      Navigator.of(context).pop(false);
      return;
    }
    popUntilApp(context);
  }

  static void backFromLoginPin(BuildContext context, {required bool embeddedInModule}) {
    if (embeddedInModule) {
      Navigator.of(context).pop(false);
      return;
    }
    popOrReplace(context, Routes.phoneInput);
  }

  static void backFromRegistration(BuildContext context, {required bool embeddedInModule}) {
    if (embeddedInModule) {
      Navigator.of(context).pop();
      return;
    }
    popOrReplace(context, Routes.phoneInput);
  }
}
