import 'package:flutter/material.dart';

import 'package:app/src/core/session/mon_peya.session.dart';

/// Pushes login / registration above tab content and hides the bottom navigation bar.
Future<T?> pushFullScreenAuth<T>(BuildContext context, Widget screen) async {
  MonPeyaSession.instance.beginAuthOverlay();
  try {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (_) => screen,
      ),
    );
  } finally {
    MonPeyaSession.instance.endAuthOverlay();
  }
}
