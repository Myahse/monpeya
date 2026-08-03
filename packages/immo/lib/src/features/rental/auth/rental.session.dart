import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/features/rental/models/rental_profile_role.dart';
import 'package:immo/src/features/rental/services/rental_api.service.dart';
import 'package:immo/src/features/rental/services/rental_realtime.service.dart';
import 'package:immo/src/shared/auth/services/immo_auth.service.dart';

/// Rental module session — guests browse; landlord data needs host login/token.
class RentalSession extends ChangeNotifier {
  RentalSession({RentalApiService? api}) : _api = api ?? RentalApiService.instance {
    ImmoHostBridge.sessionChanges?.addListener(_onHostSessionChanged);
  }

  static const _profileRoleKey = '@rental_profile_role';

  final RentalApiService _api;
  final RentalRealtimeService _realtime = RentalRealtimeService.instance;

  bool _bootstrapComplete = false;
  bool _guestMode = true;
  bool _monPeyaSessionActive = false;
  bool _businessOnly = false;
  RentalProfileRole _profileRole = RentalProfileRole.seeker;
  String? _userId;
  String? _phone;
  String? _displayName;
  String? _immoLinkError;

  bool get authFailed => false;
  bool get authenticated =>
      _bootstrapComplete && !_guestMode && _userId != null && _userId!.isNotEmpty;
  /// Mon Peya PIN entered this run — profile UI, name, personal info.
  bool get monPeyaUnlocked => _monPeyaSessionActive;
  /// Mr Immo API not linked yet — favorites / landlord APIs stay gated.
  bool get guestMode => _guestMode;
  /// Mon Peya unlocked but no Immo `utilisateursId` yet.
  bool get needsImmoLink =>
      _bootstrapComplete && _monPeyaSessionActive && !authenticated;
  bool get bootstrapComplete => _bootstrapComplete;
  String? get error => _immoLinkError;
  String? get immoLinkError => _immoLinkError;
  String? get userId => _userId;
  String? get phone => _phone;

  /// Always set — defaults to Client (seeker). Switch from Profil.
  RentalProfileRole get profileRole => _profileRole;
  bool get hasProfileRole => true;
  bool get isBusiness => _profileRole.isBusiness;
  bool get isClient => _profileRole.isClient;
  /// Fournisseur account — force landlord / business UI when session is active.
  bool get businessOnlyAccount => _businessOnly;
  RentalApiService get api => _api;

  String get displayName {
    if (!_monPeyaSessionActive) return 'Utilisateur';
    final name = _displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final phone = _phone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Utilisateur';
  }

  void _onHostSessionChanged() {
    unawaited(bootstrap());
  }

  @override
  void dispose() {
    ImmoHostBridge.sessionChanges?.removeListener(_onHostSessionChanged);
    _realtime.stop();
    super.dispose();
  }

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _guestMode = true;
    _monPeyaSessionActive = false;
    _businessOnly = false;
    _userId = null;
    _phone = null;
    _displayName = null;
    _immoLinkError = null;

    try {
      final host = ImmoHostBridge.auth;
      if (host != null && await host.isSessionActive()) {
        _monPeyaSessionActive = true;
        _businessOnly = await ImmoHostBridge.isBusinessOnlyAccount();
        _displayName = await host.displayName();
        _phone = await host.getPhone();

        if (_businessOnly) {
          _profileRole = RentalProfileRole.landlord;
          await prefs.setString(
            _profileRoleKey,
            RentalProfileRole.landlord.storageKey,
          );
        } else {
          _profileRole =
              RentalProfileRole.tryParse(prefs.getString(_profileRoleKey)) ??
                  RentalProfileRole.seeker;
        }

        final result = await ImmoAuthService(client: _api.client).ensureSession(
          apiClient: _api.client,
        );
        final linkedId = result.userId ?? await host.immoUserId();
        if (result.ok && linkedId != null && linkedId.isNotEmpty) {
          _guestMode = false;
          _userId = linkedId;
          _immoLinkError = null;
          final token = result.token?.isNotEmpty == true
              ? result.token
              : await host.authToken();
          if (token != null && token.isNotEmpty) {
            _api.client.setAuthToken(token);
          }
        } else {
          _immoLinkError = result.error ??
              'Impossible de lier le compte Mr Immo pour les favoris.';
          if (kDebugMode) {
            debugPrint('[RentalSession] Immo link failed: $_immoLinkError');
          }
        }
      }
      // Guests always browse as seekers so available listings show without login.
      // Persisted landlord/business prefs apply again after Immo auth succeeds.
      if (_guestMode) {
        _profileRole = RentalProfileRole.seeker;
      }
    } catch (e) {
      _guestMode = true;
      _userId = null;
      _immoLinkError = e.toString();
      _profileRole = RentalProfileRole.seeker;
    }

    _bootstrapComplete = true;
    _realtime.start(apiClient: _api.client, userId: _userId);
    _realtime.updateUserId(_userId);
    notifyListeners();
  }

  /// Ensures Mon Peya unlock + Immo `utilisateursId` for favorites / writes.
  Future<bool> ensureImmoReady(BuildContext context) async {
    if (authenticated) return true;

    if (!_monPeyaSessionActive) {
      final ok = await ImmoHostBridge.ensureLoggedIn(context);
      if (!ok) return false;
    }

    await bootstrap();
    return authenticated;
  }

  Future<void> setProfileRole(RentalProfileRole role) async {
    if (_businessOnly && role.isClient) return;
    // Landlord UI needs a linked Immo account; guests stay on browse (seeker).
    if (_guestMode && role.isBusiness) return;
    if (_profileRole == role) return;
    _profileRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileRoleKey, role.storageKey);
    notifyListeners();
  }
}
