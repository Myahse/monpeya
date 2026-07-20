import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo/src/features/rental/models/rental_profile_role.dart';
import 'package:immo/src/features/rental/services/rental_api.service.dart';

/// Rental module session — profile role drives the home experience until auth is wired.
class RentalSession extends ChangeNotifier {
  RentalSession({RentalApiService? api}) : _api = api ?? RentalApiService.instance;

  static const _profileRoleKey = '@rental_profile_role';

  final RentalApiService _api;

  bool _bootstrapComplete = false;
  bool _guestMode = true;
  RentalProfileRole? _profileRole;
  String? _userId;
  String? _phone;

  bool get authFailed => false;
  bool get authenticated => _bootstrapComplete;
  bool get guestMode => _guestMode;
  String? get error => null;
  String? get userId => _userId;
  String? get phone => _phone;
  RentalProfileRole? get profileRole => _profileRole;
  bool get hasProfileRole => _profileRole != null;
  RentalApiService get api => _api;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _profileRole = RentalProfileRole.tryParse(prefs.getString(_profileRoleKey));
    _guestMode = true;
    _userId = null;
    _phone = null;
    _bootstrapComplete = true;
    notifyListeners();
  }

  Future<void> setProfileRole(RentalProfileRole role) async {
    _profileRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileRoleKey, role.storageKey);
    notifyListeners();
  }
}
