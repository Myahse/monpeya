import '../../host/immo_host_bridge.dart';
import '../services/immo_api_client.dart';

/// Phone + PIN auth for Mr Immo API (same model as Mon Peya Pay).
class ImmoAuthService {
  ImmoAuthService({ImmoApiClient? client}) : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  static const loginPath = '/api/auth/login';
  static const _loginTimeout = Duration(seconds: 4);

  /// Tries stored JWT, otherwise logs in with Mon Peya phone + PIN.
  Future<ImmoAuthResult> ensureSession({
    required ImmoApiClient apiClient,
  }) async {
    final registered = await ImmoHostBridge.requireAuth.isRegistered();
    if (!registered) {
      return const ImmoAuthResult.failure('Connectez-vous à Mon Peya avec votre téléphone et votre code PIN.');
    }

    final stored = await ImmoHostBridge.requireAuth.authToken();
    if (stored != null && stored.isNotEmpty) {
      apiClient.setAuthToken(stored);
      final userId = await ImmoHostBridge.requireAuth.immoUserId();
      return ImmoAuthResult.success(token: stored, userId: userId);
    }

    final phone = await ImmoHostBridge.requireAuth.getPhone();
    if (phone == null || phone.isEmpty) {
      return const ImmoAuthResult.failure('Connectez-vous à Mon Peya avec votre téléphone.');
    }

    final pin = await ImmoHostBridge.requireAuth.getPinForPhone(phone);
    if (pin == null || pin.isEmpty) {
      return const ImmoAuthResult.failure('Code PIN Mon Peya introuvable.');
    }

    return loginWithPhoneAndPin(
      phone: phone,
      pin: pin,
      apiClient: apiClient,
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
        lastFailure = ImmoAuthResult.failure(response.error ?? 'Connexion impossible');
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

      final userId = (data['utilisateursId'] ?? data['locatairesId'] ?? data['id'])
          ?.toString();

      await ImmoHostBridge.requireAuth.setAuthToken(token);
      if (userId != null) await ImmoHostBridge.requireAuth.setImmoUserId(userId);

      apiClient.setAuthToken(token);
      return ImmoAuthResult.success(token: token, userId: userId);
    }

    return lastFailure ??
        const ImmoAuthResult.failure(
          'Aucun compte Mr Immo lié à ce numéro. Utilisez le même téléphone que Mon Peya.',
        );
  }

  List<String> _phoneLoginCandidates(String phone) {
    final normalized = phone.trim().replaceAll(' ', '');
    final set = <String>{normalized};
    if (normalized.startsWith('+225')) {
      set.add(normalized.substring(4));
      set.add('0${normalized.substring(4)}');
    }
    if (normalized.startsWith('225') && normalized.length > 3) {
      set.add('+${normalized}');
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
  const ImmoAuthResult._({
    required this.ok,
    this.token,
    this.userId,
    this.error,
  });

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
