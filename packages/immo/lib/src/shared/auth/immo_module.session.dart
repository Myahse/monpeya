import 'package:flutter/foundation.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/shared/auth/services/immo_auth.service.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

/// Shared Mr Immo session — guests browse; personal data needs host login/token.
class ImmoModuleSession extends ChangeNotifier {
  ImmoModuleSession({ImmoApiClient? apiClient})
      : _apiClient = apiClient ?? ImmoApiClient();

  final ImmoApiClient _apiClient;

  bool _bootstrapComplete = false;
  bool _guestMode = true;
  String? _userId;
  String? _phone;
  String? _displayName;

  bool get authFailed => false;
  bool get authenticated => _bootstrapComplete && !_guestMode;
  bool get guestMode => _guestMode;
  String? get error => null;
  String? get userId => _userId;
  String? get phone => _phone;
  String? get displayName => _displayName;
  ImmoApiClient get client => _apiClient;

  Future<void> bootstrap() async {
    _guestMode = true;
    _userId = null;
    _phone = null;
    _displayName = null;

    try {
      final host = ImmoHostBridge.auth;
      final active = host != null && await host.isSessionActive();
      if (active) {
        final result = await ImmoAuthService(client: _apiClient).ensureSession(
          apiClient: _apiClient,
        );
        if (result.ok) {
          _guestMode = false;
          _userId = result.userId ?? await host.immoUserId();
          _phone = await host.getPhone();
          _displayName = await host.displayName();
        }
      }
    } catch (_) {
      _guestMode = true;
      _userId = null;
    }

    _bootstrapComplete = true;
    notifyListeners();
  }
}
