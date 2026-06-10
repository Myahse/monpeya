import 'package:flutter/foundation.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/shared/auth/services/immo_auth.service.dart';

/// Mon Peya–backed session for Mr Immo modules. Opens in guest mode; syncs JWT when signed in.
class ImmoModuleSession extends ChangeNotifier {
  ImmoModuleSession({ImmoApiClient? apiClient}) : _apiClient = apiClient ?? ImmoApiClient();

  final ImmoApiClient _apiClient;
  final _auth = ImmoAuthService();

  bool _bootstrapComplete = false;
  bool _authenticated = false;
  bool _guestMode = false;
  String? _error;
  String? _userId;
  String? _phone;

  /// True only after bootstrap finished without being able to show module UI.
  bool get authFailed => _bootstrapComplete && !_authenticated;

  bool get authenticated => _authenticated;
  bool get guestMode => _guestMode;
  String? get error => _error;
  String? get userId => _userId;
  String? get phone => _phone;
  ImmoApiClient get client => _apiClient;

  Future<void> bootstrap() async {
    _error = null;
    _guestMode = false;

    final registered = await ImmoHostBridge.requireAuth.isRegistered();
    if (!registered) {
      _authenticated = true;
      _guestMode = true;
      _bootstrapComplete = true;
      notifyListeners();
      return;
    }

    _phone = await ImmoHostBridge.requireAuth.getPhone();
    _userId = await ImmoHostBridge.requireAuth.immoUserId();

    final stored = await ImmoHostBridge.requireAuth.authToken();
    if (stored != null && stored.isNotEmpty) {
      _apiClient.setAuthToken(stored);
    }

    _authenticated = true;
    _bootstrapComplete = true;
    notifyListeners();

    final sessionActive = await ImmoHostBridge.requireAuth.isSessionActive();
    if (!sessionActive) {
      _guestMode = true;
      notifyListeners();
      return;
    }

    final result = await _auth.ensureSession(apiClient: _apiClient);
    if (!result.ok) {
      _guestMode = true;
      _error = result.error;
      notifyListeners();
      return;
    }

    _guestMode = false;
    _userId = result.userId ?? await ImmoHostBridge.requireAuth.immoUserId();
    notifyListeners();
  }
}
