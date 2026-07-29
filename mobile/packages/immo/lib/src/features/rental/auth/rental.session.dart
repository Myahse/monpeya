import 'package:flutter/foundation.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/shared/auth/services/immo_auth.service.dart';
import 'package:immo/src/features/rental/services/rental_api.service.dart';

/// Rental module session — opens instantly; Mr Immo JWT syncs in background.
class RentalSession extends ChangeNotifier {
  RentalSession({RentalApiService? api}) : _api = api ?? RentalApiService.instance;

  final RentalApiService _api;
  final _auth = ImmoAuthService();

  bool _bootstrapComplete = false;
  bool _authenticated = false;
  String? _error;
  String? _userId;
  String? _phone;

  bool get authFailed => _bootstrapComplete && !_authenticated;
  bool get authenticated => _authenticated;
  String? get error => _error;
  String? get userId => _userId;
  String? get phone => _phone;
  RentalApiService get api => _api;

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
      _api.client.setAuthToken(stored);
    }

    _authenticated = true;
    _bootstrapComplete = true;
    notifyListeners();

    final result = await _auth.ensureSession(apiClient: _api.client);
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
