import 'package:flutter/foundation.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/features/rental/config/rental_api.endpoints.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

/// Phone + PIN auth for Mr Immo API (same model as Mon Peya Pay).
///
/// When login/lookup fails after a validated Mon Peya session, provisions a
/// rental `utilisateurs` row via `POST /api/utilisateurs/create`.
class ImmoAuthService {
  ImmoAuthService({ImmoApiClient? client}) : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  static const loginPath = '/api/auth/login';
  static const _loginTimeout = Duration(seconds: 8);

  /// Tries stored JWT, phone+PIN login, phone lookup, then auto-create.
  Future<ImmoAuthResult> ensureSession({
    required ImmoApiClient apiClient,
  }) async {
    final registered = await ImmoHostBridge.requireAuth.isRegistered();
    if (!registered) {
      return const ImmoAuthResult.failure(
        'Connectez-vous à Mon Peya avec votre téléphone et votre code PIN.',
      );
    }

    final phone = await ImmoHostBridge.requireAuth.getPhone();
    final stored = await ImmoHostBridge.requireAuth.authToken();
    var userId = await ImmoHostBridge.requireAuth.immoUserId();

    if (stored != null && stored.isNotEmpty) {
      apiClient.setAuthToken(stored);
      if (userId != null && userId.isNotEmpty) {
        return ImmoAuthResult.success(token: stored, userId: userId);
      }
      if (phone != null && phone.isNotEmpty) {
        final resolved = await resolveUserIdByPhone(phone);
        if (resolved != null && resolved.isNotEmpty) {
          await ImmoHostBridge.requireAuth.setImmoUserId(resolved);
          return ImmoAuthResult.success(token: stored, userId: resolved);
        }
      }
    }

    if (phone == null || phone.isEmpty) {
      return const ImmoAuthResult.failure(
        'Connectez-vous à Mon Peya avec votre téléphone.',
      );
    }

    final pin = await ImmoHostBridge.requireAuth.getPinForPhone(phone);
    if (pin != null && pin.isNotEmpty) {
      final loginResult = await loginWithPhoneAndPin(
        phone: phone,
        pin: pin,
        apiClient: apiClient,
      );
      if (loginResult.ok &&
          loginResult.userId != null &&
          loginResult.userId!.isNotEmpty) {
        return loginResult;
      }
      if (kDebugMode) {
        debugPrint(
          '[ImmoAuth] login failed: ${loginResult.error} — trying phone lookup',
        );
      }
    }

    final resolved = await resolveUserIdByPhone(phone);
    if (resolved != null && resolved.isNotEmpty) {
      await ImmoHostBridge.requireAuth.setImmoUserId(resolved);
      final token = await ImmoHostBridge.requireAuth.authToken();
      if (token != null && token.isNotEmpty) {
        apiClient.setAuthToken(token);
      }
      return ImmoAuthResult.success(token: token ?? '', userId: resolved);
    }

    // Subscription / Mon Peya session OK but no Immo row yet → provision rental user.
    if (kDebugMode) {
      debugPrint('[ImmoAuth] no Immo user for phone — provisioning rental account');
    }
    final provisioned = await provisionRentalUser(phone: phone);
    if (provisioned.ok &&
        provisioned.userId != null &&
        provisioned.userId!.isNotEmpty) {
      return provisioned;
    }

    return ImmoAuthResult.failure(
      provisioned.error ??
          'Aucun compte Mr Immo trouvé pour ce numéro. '
              'Utilisez le même téléphone que sur Mr Immo.',
    );
  }

  Future<ImmoAuthResult> loginWithPhoneAndPin({
    required String phone,
    required String pin,
    required ImmoApiClient apiClient,
  }) async {
    final identifiers = _phoneLoginCandidates(phone);
    ImmoAuthResult? lastFailure;

    for (final login in identifiers) {
      final response = await _client.postJson(
        loginPath,
        body: {'login': login, 'password': pin},
        timeout: _loginTimeout,
      );

      if (!response.success || response.data == null) {
        lastFailure =
            ImmoAuthResult.failure(response.error ?? 'Connexion impossible');
        final err = response.error ?? '';
        if (err.contains('TimeoutException') || err.contains('SocketException')) {
          break;
        }
        continue;
      }

      final data = response.data!;
      if (data['suspended'] == true) {
        return const ImmoAuthResult.failure('Compte Mr Immo suspendu.');
      }

      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        lastFailure = const ImmoAuthResult.failure('Jeton API manquant.');
        continue;
      }

      final userId = _extractUserId(data);
      await ImmoHostBridge.requireAuth.setAuthToken(token);
      if (userId != null && userId.isNotEmpty) {
        await ImmoHostBridge.requireAuth.setImmoUserId(userId);
      }

      apiClient.setAuthToken(token);
      return ImmoAuthResult.success(token: token, userId: userId);
    }

    return lastFailure ??
        const ImmoAuthResult.failure(
          'Aucun compte Mr Immo lié à ce numéro. '
          'Utilisez le même téléphone que Mon Peya.',
        );
  }

  /// Creates a Mr Immo Location user after Mon Peya subscription / session.
  ///
  /// `POST /api/utilisateurs/create` — password is auto-generated server-side.
  Future<ImmoAuthResult> provisionRentalUser({required String phone}) async {
    final phoneForDb = _preferredPhoneForCreate(phone);
    final names = await _displayNameParts();
    final isBusiness = await ImmoHostBridge.isBusinessOnlyAccount();
    final niveauAcces = isBusiness ? 'PROPRIETAIRE' : 'LOCATAIRE';
    final emails = _emailCandidates(phoneForDb);

    for (final email in emails) {
      final response = await _client.postJson(
        RentalApiEndpoints.createUser,
        body: {
          'data': {
            'nom': names.nom,
            'prenoms': names.prenoms,
            'email': email,
            'numeroTelephone': phoneForDb,
            'niveauAcces': niveauAcces,
          },
        },
        timeout: _loginTimeout,
      );

      if (!response.success || response.data == null) {
        if (kDebugMode) {
          debugPrint('[ImmoAuth] create user HTTP fail: ${response.error}');
        }
        continue;
      }

      final data = response.data!;
      if (data['hasError'] == true) {
        final msg = (data['status'] is Map)
            ? (data['status'] as Map)['message']?.toString()
            : data['message']?.toString();
        if (kDebugMode) {
          debugPrint('[ImmoAuth] create user business fail: $msg');
        }
        // Phone already exists under another format — resolve again.
        final lower = (msg ?? '').toLowerCase();
        if (lower.contains('phone') ||
            lower.contains('téléphone') ||
            lower.contains('telephone') ||
            lower.contains('already exists') ||
            lower.contains('existe')) {
          final existing = await resolveUserIdByPhone(phone);
          if (existing != null && existing.isNotEmpty) {
            await ImmoHostBridge.requireAuth.setImmoUserId(existing);
            return ImmoAuthResult.success(token: '', userId: existing);
          }
        }
        // Email taken — try next synthetic email.
        if (lower.contains('email')) continue;
        return ImmoAuthResult.failure(
          msg ?? 'Impossible de créer le compte Mr Immo.',
        );
      }

      final userId = _userIdFromEnvelope(data);
      if (userId == null || userId.isEmpty) {
        // Create may have succeeded without item — re-lookup.
        final existing = await resolveUserIdByPhone(phoneForDb);
        if (existing != null && existing.isNotEmpty) {
          await ImmoHostBridge.requireAuth.setImmoUserId(existing);
          if (kDebugMode) {
            debugPrint('[ImmoAuth] provisioned via re-lookup: $existing');
          }
          return ImmoAuthResult.success(token: '', userId: existing);
        }
        continue;
      }

      await ImmoHostBridge.requireAuth.setImmoUserId(userId);
      if (kDebugMode) {
        debugPrint('[ImmoAuth] provisioned rental user: $userId ($email)');
      }
      return ImmoAuthResult.success(token: '', userId: userId);
    }

    return const ImmoAuthResult.failure(
      'Impossible de créer le compte Mr Immo Location pour ce numéro.',
    );
  }

  /// `POST /api/utilisateurs/getByCriteria` with phone variants.
  Future<String?> resolveUserIdByPhone(String phone) async {
    for (final candidate in _phoneLoginCandidates(phone)) {
      try {
        final response = await _client.postJson(
          RentalApiEndpoints.usersByCriteria,
          body: {
            'data': {'numeroTelephone': candidate},
          },
          timeout: _loginTimeout,
        );
        if (!response.success || response.data == null) continue;
        final id = _userIdFromEnvelope(response.data!);
        if (id != null && id.isNotEmpty) return id;
      } catch (_) {
        // try next candidate
      }
    }
    return null;
  }

  Future<({String nom, String prenoms})> _displayNameParts() async {
    final raw = (await ImmoHostBridge.requireAuth.displayName())?.trim();
    if (raw == null || raw.isEmpty || raw == 'Utilisateur') {
      return (nom: 'MonPeya', prenoms: 'Client');
    }
    final parts = raw.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return (nom: 'MonPeya', prenoms: parts.first);
    }
    return (
      prenoms: parts.first,
      nom: parts.sublist(1).join(' '),
    );
  }

  /// Prefer local CI format `0XXXXXXXXX` for DB uniqueness checks.
  String _preferredPhoneForCreate(String phone) {
    final candidates = _phoneLoginCandidates(phone);
    for (final c in candidates) {
      if (c.startsWith('0') && c.length >= 10) return c;
    }
    return candidates.first;
  }

  List<String> _emailCandidates(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final base = digits.isEmpty ? 'user' : digits;
    return [
      '$base@monpeya.com',
      'mp$base@monpeya.com',
      'rental.$base@monpeya.com',
    ];
  }

  String? _userIdFromEnvelope(Map<String, dynamic> data) {
    if (data['hasError'] == true) return null;
    final items = data['items'];
    if (items is List) {
      for (final raw in items) {
        if (raw is! Map) continue;
        final id = _extractUserId(Map<String, dynamic>.from(raw));
        if (id != null && id.isNotEmpty) return id;
      }
    }
    final item = data['item'];
    if (item is Map) {
      return _extractUserId(Map<String, dynamic>.from(item));
    }
    return _extractUserId(data);
  }

  String? _extractUserId(Map<String, dynamic> data) {
    final nested = data['utilisateur'];
    if (nested is Map) {
      final fromNested = _extractUserId(Map<String, dynamic>.from(nested));
      if (fromNested != null) return fromNested;
    }
    final raw = data['utilisateursId'] ??
        data['locatairesId'] ??
        data['id'] ??
        data['userId'];
    if (raw == null) return null;
    final id = raw.toString().trim();
    return id.isEmpty ? null : id;
  }

  List<String> _phoneLoginCandidates(String phone) {
    final normalized = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
    final set = <String>{normalized};
    if (normalized.startsWith('+225')) {
      set.add(normalized.substring(4));
      set.add('0${normalized.substring(4)}');
    }
    if (normalized.startsWith('225') && normalized.length > 3) {
      set.add('+$normalized');
      set.add('0${normalized.substring(3)}');
    }
    if (normalized.startsWith('0')) {
      set.add('+225${normalized.substring(1)}');
      set.add('225${normalized.substring(1)}');
    }
    return set.toList();
  }
}

class ImmoAuthResult {
  const ImmoAuthResult.success({required this.token, this.userId})
      : ok = true,
        error = null;

  const ImmoAuthResult.failure(this.error)
      : ok = false,
        token = null,
        userId = null;

  final bool ok;
  final String? token;
  final String? userId;
  final String? error;
}
