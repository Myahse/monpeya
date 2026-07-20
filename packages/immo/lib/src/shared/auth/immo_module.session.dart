import 'package:flutter/foundation.dart';

import 'package:immo/src/shared/services/immo_api.client.dart';

/// Shared Mr Immo session — runs without Mon Peya / PeyaPay auth until integrated later.
class ImmoModuleSession extends ChangeNotifier {
  ImmoModuleSession({ImmoApiClient? apiClient}) : _apiClient = apiClient ?? ImmoApiClient();

  final ImmoApiClient _apiClient;

  bool _bootstrapComplete = false;
  bool _guestMode = true;
  String? _userId;
  String? _phone;

  bool get authFailed => false;
  bool get authenticated => _bootstrapComplete;
  bool get guestMode => _guestMode;
  String? get error => null;
  String? get userId => _userId;
  String? get phone => _phone;
  ImmoApiClient get client => _apiClient;

  Future<void> bootstrap() async {
    _guestMode = true;
    _userId = null;
    _phone = null;
    _bootstrapComplete = true;
    notifyListeners();
  }
}
