import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

/// Code client + 4-digit PIN sign-in for a standalone Mr Immo app (one per role), standing
/// in for Mon Peya as [ImmoHostAuth]. The code client is the phone number of the account.
/// The session is kept in SharedPreferences under [appId].
class ImmoProAuth implements ImmoHostAuth {
  ImmoProAuth({required this.appId, ImmoApiClient? client})
      : _client = client ?? ImmoApiClient();

  final String appId;
  final ImmoApiClient _client;

  static const _pinLoginPath = '/api/auth/pin-login';
  static const _logoutPath = '/api/auth/logout';
  static const _validatePath = '/api/auth/validate';
  static const _timeout = Duration(seconds: 10);

  /// Signs in. Returns null on success, or the message to show.
  /// [allows] says whether the account's niveau d'accès belongs in this app;
  /// when it does not, nothing is kept and [wrongRoleMessage] is returned.
  Future<String?> login({
    required String codeClient,
    required String pin,
    required bool Function(String? accessLevel) allows,
    required String wrongRoleMessage,
  }) async {
    final code = codeClient.trim();
    final response = await _client.postJson(
      _pinLoginPath,
      body: {'codeClient': code, 'pin': pin},
      timeout: _timeout,
    );
    final data = response.data;
    if (!response.success || data == null) {
      // The backend words its refusals (wrong PIN, locked, no PIN yet, suspended)
      if (data != null && response.error != null) return response.error;
      return _unreachable(response.error)
          ? 'Serveur injoignable. Vérifiez votre connexion puis réessayez.'
          : (response.error ?? 'Connexion impossible.');
    }

    final token = data['token']?.toString() ?? '';
    final userId = data['utilisateursId']?.toString() ?? '';
    final level = data['niveauAcces']?.toString();
    if (token.isEmpty) return 'Connexion impossible : jeton manquant.';
    if (userId.isEmpty || !allows(level)) {
      await _logoutRemote(token);
      return wrongRoleMessage;
    }

    final name = [data['prenoms'], data['nom']]
        .map((p) => p?.toString().trim() ?? '')
        .where((p) => p.isNotEmpty)
        .join(' ');
    await _write('token', token);
    await _write('userId', userId);
    await _write('name', name);
    await _write('email', data['email']?.toString());
    await _write('accessLevel', level);
    await _write('codeClient', code);
    return null;
  }

  /// The code client last signed in with; kept after sign-out, as Mon Peya keeps the phone.
  Future<String?> lastCodeClient() => _read('codeClient');

  /// Drops a stored session the backend no longer accepts (expired or logged out).
  /// Kept when the server cannot be reached, so the app still opens offline.
  Future<void> restore() async {
    final token = await authToken();
    if (token == null) return;
    final response = await _client.postJson(
      _validatePath,
      body: {'token': token},
      timeout: _timeout,
    );
    if (!response.success && response.data?['valid'] == false) await _clear();
  }

  Future<void> logout() async {
    final token = await authToken();
    await _clear();
    if (token != null) await _logoutRemote(token);
  }

  Future<void> _logoutRemote(String token) async {
    _client.setAuthToken(token);
    await _client.postJson(_logoutPath, timeout: _timeout);
    _client.setAuthToken(null);
  }

  Future<void> _clear() async {
    for (final name in const ['token', 'userId', 'name', 'email', 'accessLevel']) {
      await _write(name, null);
    }
  }

  static bool _unreachable(String? error) {
    final e = error ?? '';
    return e.contains('SocketException') ||
        e.contains('TimeoutException') ||
        e.contains('ClientException') ||
        e.contains('Connection');
  }

  String _key(String name) => 'immo_pro.$appId.$name';

  Future<String?> _read(String name) async {
    final value = (await SharedPreferences.getInstance()).getString(_key(name));
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _write(String name, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_key(name));
    } else {
      await prefs.setString(_key(name), value);
    }
  }

  @override
  Future<bool> isRegistered() async => await authToken() != null;

  @override
  Future<bool> isSessionActive() async =>
      await authToken() != null && await immoUserId() != null;

  @override
  Future<String?> displayName() => _read('name');

  /// The identity line under the name on the profile: the code client (phone number).
  @override
  Future<String?> getPhone() => _read('codeClient');

  @override
  Future<String?> getPinForPhone(String phone) async => null;

  @override
  Future<String?> authToken() => _read('token');

  @override
  Future<void> setAuthToken(String? token) => _write('token', token);

  @override
  Future<String?> immoUserId() => _read('userId');

  @override
  Future<void> setImmoUserId(String? userId) => _write('userId', userId);

  /// The staff apps have no Mon Peya session.
  @override
  Future<String?> monPeyaAccessToken() async => null;
}
