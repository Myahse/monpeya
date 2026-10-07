import 'package:flutter/material.dart';

typedef GrenierHostExitHandler = void Function(BuildContext context);
typedef GrenierEnsureSession = Future<bool> Function(BuildContext context);

/// Mon Peya identity shared with Mon Grenier (only after the user agrees).
class GrenierHostProfile {
  const GrenierHostProfile({required this.fullName, this.phone});

  final String fullName;
  final String? phone;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

typedef GrenierProfileLoader = Future<GrenierHostProfile?> Function();

class GrenierHostBridge {
  GrenierHostBridge._();

  static GrenierHostExitHandler? onExitModule;
  static GrenierEnsureSession? ensureSession;

  /// Provided by the host: the signed-in Mon Peya user, or null for a guest.
  static GrenierProfileLoader? loadProfile;

  static Future<bool> ensureLoggedIn(BuildContext context) async {
    final handler = ensureSession;
    if (handler == null) return true;
    return handler(context);
  }

  static Future<GrenierHostProfile?> profile() async {
    final loader = loadProfile;
    if (loader == null) return null;
    try {
      return await loader();
    } catch (_) {
      return null;
    }
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
