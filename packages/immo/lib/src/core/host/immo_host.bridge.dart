import 'package:flutter/material.dart';

/// Host-provided session data from Mon Peya (phone + PIN model).
abstract class ImmoHostAuth {
  /// Whether the user completed Mon Peya phone + PIN registration.
  Future<bool> isRegistered();

  Future<String?> getPhone();
  Future<String?> getPinForPhone(String phone);
  Future<String?> authToken();
  Future<void> setAuthToken(String? token);
  Future<String?> immoUserId();
  Future<void> setImmoUserId(String? userId);
}

typedef ImmoHostExitHandler = void Function(BuildContext context);

/// Registered by Mon Peya before opening Mr Immo modules.
class ImmoHostBridge {
  ImmoHostBridge._();

  static ImmoHostAuth? auth;
  static ImmoHostExitHandler? onExitModule;

  static ImmoHostAuth get requireAuth {
    final host = auth;
    if (host == null) {
      throw StateError('ImmoHostBridge.auth not configured by Mon Peya shell.');
    }
    return host;
  }

  /// Leave Mr Immo and return to the Mon Peya shell (home tabs).
  static void exitModule(BuildContext context) {
    final handler = onExitModule;
    if (handler != null) {
      handler(context);
      return;
    }
    Navigator.of(context).maybePop();
  }
}
