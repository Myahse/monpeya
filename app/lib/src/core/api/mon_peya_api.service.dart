import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/api/models/mon_peya_auth.models.dart';
import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/core/api/models/mon_peya_wallet.models.dart';
import 'package:app/src/core/api/mon_peya_api.config.dart';
import 'package:app/src/core/api/mon_peya_api.exception.dart';

/// HTTP client for the Monpeya backend (`POST /v1/*`, `{ data }` envelope).
class MonPeyaApiService {
  MonPeyaApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<MonPeyaAuthSession> lookupPhone(String phone) async {
    return _postForItem(
      '/v1/auth/lookup',
      data: {'phone': _digitsOnly(phone)},
      parser: MonPeyaAuthSession.fromJson,
      errorMessage: 'Recherche du numéro impossible',
    );
  }

  Future<void> sendOtp(String phone) async {
    final device = await _devicePayload(phone: phone);
    await _postSuccess(
      '/v1/auth/otp/send',
      data: device,
      errorMessage: 'Envoi OTP impossible',
    );
  }

  Future<MonPeyaAuthSession> verifyOtp({
    required String phone,
    required String otpCode,
  }) async {
    final device = await _devicePayload(phone: phone);
    return _postForItem(
      '/v1/auth/otp/verify',
      data: {
        ...device,
        'otpCode': otpCode.trim(),
      },
      parser: MonPeyaAuthSession.fromJson,
      errorMessage: 'Code OTP invalide',
    );
  }

  Future<MonPeyaAuthSession> login({
    required String phone,
    required String pin,
  }) async {
    final device = await _devicePayload(phone: phone, pin: pin);
    return _postForItem(
      '/v1/auth/login',
      data: device,
      parser: MonPeyaAuthSession.fromJson,
      errorMessage: 'Connexion impossible',
    );
  }

  Future<MonPeyaAuthSession> refresh({required String refreshToken}) async {
    return _postForItem(
      '/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
      parser: MonPeyaAuthSession.fromJson,
      errorMessage: 'Session expirée',
    );
  }

  Future<void> logout({required String accessToken}) async {
    await _postSuccess(
      '/v1/auth/logout',
      data: {'accessToken': accessToken},
      errorMessage: 'Déconnexion impossible',
    );
  }

  Future<MonPeyaAuthUser> me({required String accessToken}) async {
    return _postForItem(
      '/v1/auth/me',
      data: {'accessToken': accessToken},
      parser: MonPeyaAuthUser.fromJson,
      errorMessage: 'Session invalide',
      allowUnauthorized: true,
    );
  }

  Future<MonPeyaAccessDecision> checkAccess({
    required String moduleCode,
    String? actionCode,
    String? accessToken,
  }) async {
    return _postForItem(
      '/v1/access/check',
      data: {
        'moduleCode': moduleCode,
        if (actionCode != null && actionCode.isNotEmpty) 'actionCode': actionCode,
        if (accessToken != null && accessToken.isNotEmpty) 'accessToken': accessToken,
      },
      parser: MonPeyaAccessDecision.fromJson,
      errorMessage: 'Contrôle d’accès impossible',
    );
  }

  Future<List<MonPeyaPlan>> listPlans({String? moduleCode, String? role}) async {
    return _postForItems(
      '/v1/plans',
      data: {
        if (moduleCode != null && moduleCode.isNotEmpty) 'moduleCode': moduleCode,
        if (role != null && role.isNotEmpty) 'role': role,
      },
      parser: MonPeyaPlan.fromJson,
      errorMessage: 'Impossible de charger les formules',
    );
  }

  Future<List<MonPeyaSubscription>> mySubscriptions({
    required String accessToken,
    String? moduleCode,
    String? role,
  }) async {
    return _postForItems(
      '/v1/subscriptions/me',
      data: {
        'accessToken': accessToken,
        if (moduleCode != null && moduleCode.isNotEmpty) 'moduleCode': moduleCode,
        if (role != null && role.isNotEmpty) 'role': role,
      },
      parser: MonPeyaSubscription.fromJson,
      errorMessage: 'Impossible de charger vos abonnements',
      allowEmpty: true,
    );
  }

  Future<MonPeyaSubscription> subscribe({
    required String accessToken,
    required String planCode,
    String? moduleCode,
    String role = 'CLIENT',
  }) async {
    return _postForItem(
      '/v1/subscriptions/subscribe',
      data: {
        'accessToken': accessToken,
        'planCode': planCode,
        'role': role,
        if (moduleCode != null && moduleCode.isNotEmpty) 'moduleCode': moduleCode,
      },
      parser: MonPeyaSubscription.fromJson,
      errorMessage: 'Souscription impossible',
    );
  }

  Future<MonPeyaSubscriptionRequest> requestDeplafonnement({
    required String accessToken,
  }) async {
    return _postForItem(
      '/v1/subscriptions/requests/deplafonnement',
      data: {'accessToken': accessToken},
      parser: MonPeyaSubscriptionRequest.fromJson,
      errorMessage: 'Demande de déplafonnement impossible',
    );
  }

  Future<List<MonPeyaSubscriptionRequest>> mySubscriptionRequests({
    required String accessToken,
  }) async {
    return _postForItems(
      '/v1/subscriptions/requests/me',
      data: {'accessToken': accessToken},
      parser: MonPeyaSubscriptionRequest.fromJson,
      errorMessage: 'Impossible de charger vos demandes',
      allowEmpty: true,
    );
  }

  Future<void> ping() async {
    await _postSuccess(
      '/v1/ping',
      data: const {},
      errorMessage: 'Backend Mon Peya indisponible',
    );
  }

  Future<MonPeyaProfile> profileMe({required String accessToken}) async {
    return _postForItem(
      '/v1/profile/me',
      data: {'accessToken': accessToken},
      parser: MonPeyaProfile.fromJson,
      errorMessage: 'Profil indisponible',
    );
  }

  Future<MonPeyaProfile> profileRefresh({
    required String accessToken,
    String residenceCountry = 'CI',
  }) async {
    return _postForItem(
      '/v1/profile/refresh',
      data: {
        'accessToken': accessToken,
        'residenceCountry': residenceCountry,
      },
      parser: MonPeyaProfile.fromJson,
      errorMessage: 'Rafraîchissement profil impossible',
    );
  }

  Future<MonPeyaWalletBalance> walletBalance({
    required String accessToken,
    String? pin,
    String residenceCountry = 'CI',
  }) async {
    return _postForItem(
      '/v1/wallet/balance',
      data: {
        'accessToken': accessToken,
        'residenceCountry': residenceCountry,
        if (pin != null && pin.trim().isNotEmpty) 'pin': pin.trim(),
      },
      parser: MonPeyaWalletBalance.fromJson,
      errorMessage: 'Impossible de récupérer le solde',
    );
  }

  Future<MonPeyaWalletMovements> walletMovements({
    required String accessToken,
    String? accountNumber,
    int index = 0,
    int size = 20,
    String? startDate,
    String? endDate,
  }) async {
    return _postForItem(
      '/v1/wallet/movements',
      data: {
        'accessToken': accessToken,
        'index': index,
        'size': size,
        if (accountNumber != null && accountNumber.trim().isNotEmpty)
          'accountNumber': accountNumber.trim(),
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      },
      parser: MonPeyaWalletMovements.fromJson,
      errorMessage: 'Impossible de récupérer les mouvements',
    );
  }

  Future<MonPeyaWalletTransfer> walletTransfer({
    required String accessToken,
    required String recipientPhone,
    required int amountReceived,
    int fee = 0,
    bool payFees = false,
    String? platform,
    String? pin,
    String residenceCountry = 'CI',
  }) async {
    return _postForItem(
      '/v1/wallet/transfer',
      data: {
        'accessToken': accessToken,
        'recipientPhone': recipientPhone,
        'amountReceived': amountReceived,
        'fee': fee,
        'payFees': payFees,
        'residenceCountry': residenceCountry,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
        if (pin != null && pin.trim().isNotEmpty) 'pin': pin.trim(),
      },
      parser: MonPeyaWalletTransfer.fromJson,
      errorMessage: 'Impossible d\'effectuer le transfert',
    );
  }

  Future<MonPeyaClientSearch> clientsSearch({
    required String accessToken,
    required String phone,
  }) async {
    return _postForItem(
      '/v1/clients/search',
      data: {
        'accessToken': accessToken,
        'phone': phone,
      },
      parser: MonPeyaClientSearch.fromJson,
      errorMessage: 'Impossible de rechercher le numéro',
    );
  }

  Future<T> _postForItem<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) parser,
    required String errorMessage,
    bool allowUnauthorized = false,
  }) async {
    final envelope = await _postEnvelope(
      path,
      data: data,
      errorMessage: errorMessage,
      allowUnauthorized: allowUnauthorized,
    );
    final item = envelope.item;
    if (item == null) {
      throw MonPeyaApiException(
        message: '$errorMessage (réponse vide)',
        apiCode: envelope.code,
      );
    }
    return parser(item);
  }

  Future<List<T>> _postForItems<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) parser,
    required String errorMessage,
    bool allowUnauthorized = false,
    bool allowEmpty = false,
  }) async {
    final envelope = await _postEnvelope(
      path,
      data: data,
      errorMessage: errorMessage,
      allowUnauthorized: allowUnauthorized,
    );
    final items = envelope.items;
    if (items.isEmpty && !allowEmpty && envelope.item == null) {
      throw MonPeyaApiException(
        message: '$errorMessage (aucune formule)',
        apiCode: envelope.code,
      );
    }
    if (items.isNotEmpty) {
      return items.map(parser).toList();
    }
    if (envelope.item != null) {
      return [parser(envelope.item!)];
    }
    return const [];
  }

  Future<void> _postSuccess(
    String path, {
    required Map<String, dynamic> data,
    required String errorMessage,
  }) async {
    await _postEnvelope(path, data: data, errorMessage: errorMessage);
  }

  Future<_MonPeyaEnvelope> _postEnvelope(
    String path, {
    required Map<String, dynamic> data,
    required String errorMessage,
    bool allowUnauthorized = false,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(MonPeyaApiConfig.apiTimeout);

    return _parseEnvelope(
      response,
      errorMessage: errorMessage,
      allowUnauthorized: allowUnauthorized,
    );
  }

  _MonPeyaEnvelope _parseEnvelope(
    http.Response response, {
    required String errorMessage,
    bool allowUnauthorized = false,
  }) {
    final decoded = _decodeBody(response, errorMessage);

    if (response.statusCode == 401 && allowUnauthorized) {
      throw MonPeyaApiException(
        message: errorMessage,
        statusCode: 401,
        apiCode: '901',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MonPeyaApiException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw MonPeyaApiException(message: '$errorMessage (format inattendu)');
    }

    final hasError = decoded['hasError'] == true;
    final status = decoded['status'];
    final code = status is Map ? status['code']?.toString() : null;
    final message = status is Map ? status['message']?.toString() : null;

    if (hasError || (code != null && code != '800')) {
      throw MonPeyaApiException(
        message: (message != null && message.isNotEmpty) ? message : errorMessage,
        statusCode: response.statusCode,
        apiCode: code,
      );
    }

    final itemRaw = decoded['item'];
    final itemsRaw = decoded['items'];
    final items = <Map<String, dynamic>>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map) items.add(Map<String, dynamic>.from(e));
      }
    }

    return _MonPeyaEnvelope(
      code: code,
      item: itemRaw is Map ? Map<String, dynamic>.from(itemRaw) : null,
      items: items,
    );
  }

  dynamic _decodeBody(http.Response response, String errorMessage) {
    try {
      if (response.body.isEmpty) return const {};
      return jsonDecode(response.body);
    } catch (_) {
      throw MonPeyaApiException(message: '$errorMessage (réponse invalide)');
    }
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${MonPeyaApiConfig.baseUrl}$normalized');
  }

  static String _digitsOnly(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00225') && digits.length > 10) {
      digits = digits.substring(5);
    } else if (digits.startsWith('225') && digits.length > 10) {
      digits = digits.substring(3);
    }
    return digits;
  }

  static Future<Map<String, dynamic>> _devicePayload({
    required String phone,
    String? pin,
  }) async {
    final deviceInfo = await PeyapayDeviceInfo.getDeviceInfo();
    return {
      'phone': _digitsOnly(phone),
      'residenceCountry': 'CI',
      'imei': deviceInfo['imei'] ?? 'unknown',
      'modele': deviceInfo['modele'] ?? 'Unknown Device',
      'platform': deviceInfo['platform'] ?? deviceInfo['plateform'] ?? 'unknown',
      if (pin != null) 'pin': pin.trim(),
    };
  }
}

class _MonPeyaEnvelope {
  const _MonPeyaEnvelope({this.code, this.item, this.items = const []});

  final String? code;
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> items;
}
