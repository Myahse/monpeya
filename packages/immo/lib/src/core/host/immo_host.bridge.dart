import 'package:flutter/material.dart';

typedef ImmoBusinessOnlyResolver = Future<bool> Function();

/// Host-provided session data from Mon Peya (optional until auth is integrated).
abstract class ImmoHostAuth {
  /// Whether the user completed Mon Peya phone + PIN registration.
  Future<bool> isRegistered();

  /// Whether the user entered their PIN this app session.
  Future<bool> isSessionActive();

  /// Client display name when [isSessionActive] (Mon Peya / PeyaPay profile).
  Future<String?> displayName();

  Future<String?> getPhone();
  Future<String?> getPinForPhone(String phone);
  Future<String?> authToken();
  Future<void> setAuthToken(String? token);
  Future<String?> immoUserId();
  Future<void> setImmoUserId(String? userId);
}

typedef ImmoHostExitHandler = void Function(BuildContext context);


typedef ImmoEnsureSession = Future<bool> Function(BuildContext context);


class ImmoHostBridge {
  ImmoHostBridge._();

  
  static ImmoHostAuth? auth;
  static ImmoHostExitHandler? onExitModule;
  static ImmoEnsureSession? ensureSession;
  static ImmoBusinessOnlyResolver? resolveBusinessOnlyAccount;

  /// Mon Peya session unlock — re-bootstrap Immo when the user enters PIN.
  static Listenable? sessionChanges;

  /// Fournisseur PeyaPay (`estFournisseur: O`) without client wallet — landlord UI only.
  static Future<bool> isBusinessOnlyAccount() async {
    final resolver = resolveBusinessOnlyAccount;
    if (resolver == null) return false;
    try {
      return await resolver();
    } catch (_) {
      return false;
    }
  }

  static ImmoHostAuth get requireAuth {
    final host = auth;
    if (host == null) {
      throw StateError('ImmoHostBridge.auth not configured by Mon Peya shell.');
    }
    return host;
  }


  static Future<bool> promptLogin(BuildContext context) async {
    final handler = ensureSession;
    if (handler == null) return false;
    return handler(context);
  }

  static Future<bool> ensureLoggedIn(BuildContext context) async {
    final host = auth;
    if (host != null && await host.isSessionActive()) return true;
    if (!context.mounted) return false;
    return promptLogin(context);
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
