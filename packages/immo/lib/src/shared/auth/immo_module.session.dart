import 'package:flutter/foundation.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/shared/auth/services/immo_auth.service.dart';

/// Mon Peya–backed session for Mr Immo modules. Opens instantly; syncs JWT in background.
class ImmoModuleSession extends ChangeNotifier {
  ImmoModuleSession({ImmoApiClient? apiClient}) : _apiClient = apiClient ?? ImmoApiClient();

  final ImmoApiClient _apiClient;
  final _auth = ImmoAuthService();

  bool _bootstrapComplete = false;
  bool _authenticated = false;
  String? _error;
  String? _userId;
  String? _phone;

  /// True only after bootstrap finished without a valid Mon Peya / Mr Immo session.
  bool get authFailed => _bootstrapComplete && !_authenticated;

  bool get authenticated => _authenticated;
  String? get error => _error;
  String? get userId => _userId;
  String? get phone => _phone;
  ImmoApiClient get client => _apiClient;

  Future<void> bootstrap() async {
    _error = null;

    final registered = await ImmoHostBridge.requireAuth.isRegistered();
    if (!registered) {
      _bootstrapComplete = true;
      _authenticated = false;
      _error = 'Connectez-vous à Mon Peya avec votre téléphone et votre code PIN.';
      notifyListeners();
      return;
    }

    _phone = await ImmoHostBridge.requireAuth.getPhone();
    _userId = await ImmoHostBridge.requireAuth.immoUserId();

    final stored = await ImmoHostBridge.requireAuth.authToken();
    if (stored != null && stored.isNotEmpty) {
      _apiClient.setAuthToken(stored);
    }

    // Enter the module immediately — user is already signed in to Mon Peya.
    _authenticated = true;
    _bootstrapComplete = true;
    notifyListeners();

    final result = await _auth.ensureSession(apiClient: _apiClient);
    if (!result.ok) {
      _authenticated = false;
      _error = result.error;
      notifyListeners();
      return;
    }

    _userId = result.userId ?? await ImmoHostBridge.requireAuth.immoUserId();
    notifyListeners();
  }
}
