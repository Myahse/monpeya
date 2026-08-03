import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:peyapay/src/core/constants/peyapay_api.constants.dart';
import 'package:peyapay/src/core/utils/peyapay_device_info.util.dart';
import 'package:peyapay/src/data/models/peyapay_account_movement.model.dart';
import 'package:peyapay/src/data/models/peyapay_api.exception.dart';
import 'package:peyapay/src/data/models/peyapay_api_envelope.model.dart';
import 'package:peyapay/src/data/models/peyapay_auth_token.model.dart';
import 'package:peyapay/src/data/models/peyapay_client_state.model.dart';
import 'package:peyapay/src/data/models/peyapay_client_transfer.model.dart';
import 'package:peyapay/src/data/models/peyapay_gsm_search.model.dart';
import 'package:peyapay/src/data/models/peyapay_wallet_balance.model.dart';
import 'package:peyapay/src/data/models/peyapay_wallet_connection.model.dart';
import 'package:peyapay/src/data/services/peyapay_crypto.service.dart';

class PeyapayApiService {
  PeyapayApiService({
    http.Client? client,
    PeyapayCryptoService? crypto,
  })  : _client = client ?? http.Client(),
        _crypto = crypto ?? PeyapayCryptoService(client: client);

  final http.Client _client;
  final PeyapayCryptoService _crypto;

  String? _bearerToken;
  PeyapayClientState? _clientState;
  PeyapayWalletBalance? _walletBalance;

  String? get bearerToken => _bearerToken;
  PeyapayClientState? get clientState => _clientState;
  PeyapayWalletBalance? get walletBalance => _walletBalance;

  void setBearerToken(String? token) => _bearerToken = token;
  void setClientState(PeyapayClientState? state) => _clientState = state;
  void setWalletBalance(PeyapayWalletBalance? balance) => _walletBalance = balance;

  /// Ensures a JWT is available — uses app credentials when no user token exists.
  Future<void> ensureBearerToken({bool preferAppToken = false}) async {
    if (!preferAppToken && _bearerToken != null && _bearerToken!.isNotEmpty) {
      return;
    }

    final auth = await authenticateApp();
    setBearerToken(auth.token);
  }

  /// Runs [action] with the service (admin) bearer used by `/wClients/rechercheGsm`.
  Future<T> _withServiceBearer<T>(Future<T> Function() action) async {
    final previous = _bearerToken;
    await ensureBearerToken(preferAppToken: true);
    try {
      return await action();
    } finally {
      if (previous != null && previous.isNotEmpty) {
        setBearerToken(previous);
      }
    }
  }

  
  Future<void> hydrateBearerFrom(
    Future<String?> Function() readStoredToken, {
    bool preferAppToken = false,
  }) async {
    if (_bearerToken != null && _bearerToken!.isNotEmpty) return;

    final stored = await readStoredToken();
    if (stored != null && stored.isNotEmpty) {
      setBearerToken(stored);
      return;
    }

    await ensureBearerToken(preferAppToken: preferAppToken);
  }

  
  Future<PeyapayWalletConnection> connectClientWallet({
    required String phone,
    required String pin,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
    bool ensureToken = true,
  }) async {
    if (ensureToken) {
      await ensureBearerToken(preferAppToken: true);
    }

    final phoneDigits = _requirePhoneDigits(phone);
    final pinValue = pin.trim();
    if (pinValue.length < 4) {
      throw PeyapayApiException(message: 'Code PIN invalide');
    }

    final encryptedData = await _encryptDataPayload(
      {
        'gsmPrincipale': phoneDigits,
        'codePin': pinValue,
        'codePaysResidence': residenceCountry,
      },
      plainKeys: {'codePaysResidence'},
    );

    return _postForItem(
      '/wClients/cnx',
      data: encryptedData,
      parser: PeyapayWalletConnection.fromJson,
      errorMessage: 'Code PIN ou numéro PeyaPay incorrect',
    );
  }

  /// Obtains a client JWT via `/authclient/token` (dpayV2).
  Future<PeyapayAuthToken> loginClientWallet({
    required String phone,
    required String pin,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
  }) async {
    final phoneDigits = _requirePhoneDigits(phone);
    final pinValue = pin.trim();
    if (pinValue.length < 4) {
      throw PeyapayApiException(message: 'Code PIN invalide');
    }

    final encryptedPhone = await _crypto.encryptForApi(phoneDigits, label: 'gsmPrincipale');
    final encryptedPin = await _crypto.encryptForApi(pinValue, label: 'codePin');

    return _fetchClientToken(
      username: encryptedPhone,
      password: encryptedPin,
      residenceCountry: residenceCountry,
    );
  }

  /// Alias kept for existing call sites.
  Future<PeyapayAuthToken> authenticateClient({
    required String phone,
    required String pin,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
  }) {
    return loginClientWallet(
      phone: phone,
      pin: pin,
      residenceCountry: residenceCountry,
    );
  }

  /// Service-level token using `APP_ADMIN_USERNAME` / `APP_ADMIN_PASSWORD` from `app/.env`.
  Future<PeyapayAuthToken> authenticateApp({
    String? username,
    String? password,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
    bool encryptCredentials = false,
  }) async {
    final user = (username ?? PeyapayApiConfig.appUsername).trim();
    final pass = (password ?? PeyapayApiConfig.appPassword).trim();
    if (user.isEmpty || pass.isEmpty) {
      throw PeyapayApiException(
        message: 'Identifiants applicatifs manquants (APP_ADMIN_USERNAME / APP_ADMIN_PASSWORD dans app/.env)',
      );
    }

    final resolvedUsername = encryptCredentials ? await _crypto.encryptString(user) : user;
    final resolvedPassword = encryptCredentials ? await _crypto.encryptString(pass) : pass;
    if (resolvedUsername == null || resolvedPassword == null) {
      throw PeyapayApiException(message: 'Impossible de chiffrer les identifiants applicatifs');
    }

    return _fetchClientToken(
      username: resolvedUsername,
      password: resolvedPassword,
      residenceCountry: residenceCountry,
    );
  }

  /// Checks whether a phone number is already a PeyaPay wallet client.
  Future<PeyapayGsmSearchResult> searchGsm({
    required String phone,
    bool ensureToken = true,
    bool useServiceBearer = true,
  }) async {
    Future<PeyapayGsmSearchResult> lookup() async {
      final phoneDigits = _requirePhoneDigits(phone);
      final encryptedData = await _encryptDataPayload(
        {'gsmPrincipale': phoneDigits},
        plainKeys: const {},
      );

      final envelope = await _postEnvelope(
        '/wClients/rechercheGsm',
        data: encryptedData,
        errorMessage: 'Impossible de rechercher le numéro PeyaPay',
      );

      final items = envelope.items
              ?.map(PeyapayGsmClientProfile.fromJson)
              .toList(growable: false) ??
          const <PeyapayGsmClientProfile>[];

      final resolvedItems = items.isNotEmpty
          ? items
          : (envelope.item != null
              ? [PeyapayGsmClientProfile.fromJson(envelope.item!)]
              : const <PeyapayGsmClientProfile>[]);

      return PeyapayGsmSearchResult(
        count: envelope.count ?? resolvedItems.length,
        items: resolvedItems,
      );
    }

    if (useServiceBearer) {
      return _withServiceBearer(lookup);
    }
    return lookup();
  }

  /// Sends an OTP when the phone is not recognised via [searchGsm].
  Future<void> sendClientOtp({
    required String phone,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
    bool includeDeviceInfo = false,
    bool ensureToken = true,
  }) async {
    if (ensureToken) {
      await ensureBearerToken(preferAppToken: true);
    }

    final phoneDigits = _requirePhoneDigits(phone);
    final plain = <String, dynamic>{
      'gsmPrincipale': phoneDigits,
      'codePaysResidence': residenceCountry,
    };

    if (includeDeviceInfo) {
      final deviceInfo = await PeyapayDeviceInfo.getDeviceInfo();
      plain
        ..['imei'] = deviceInfo['imei'] ?? 'unknown'
        ..['modele'] = deviceInfo['modele'] ?? 'Unknown Device'
        ..['plateform'] = deviceInfo['plateform'] ?? 'unknown';
    }

    final encryptedData = await _encryptDataPayload(
      plain,
      plainKeys: {'codePaysResidence'},
    );

    await _postSuccess(
      '/wClients/code',
      data: encryptedData,
      errorMessage: 'Impossible d\'envoyer le code OTP PeyaPay',
    );
  }

  /// Validates an OTP received by SMS via `/wClients/verifcode`.
  Future<void> verifyOtpCode({
    required String phone,
    required String code,
    bool ensureToken = true,
  }) async {
    if (ensureToken) {
      await ensureBearerToken(preferAppToken: true);
    }

    final phoneDigits = _requirePhoneDigits(phone);
    if (code.trim().length < 4) {
      throw PeyapayApiException(message: 'Code OTP invalide');
    }

    final encryptedData = await _encryptDataPayload(
      {
        'codeValid': code.trim(),
        'login': phoneDigits,
      },
      plainKeys: const {},
    );

    await _postSuccess(
      '/wClients/verifcode',
      data: encryptedData,
      errorMessage: 'Code OTP PeyaPay incorrect',
    );
  }

  /// Verifies wallet PIN via `/wClients/verifCodePin` (encrypted `gsmPrincipale` + `codePin`).
  Future<PeyapayPinVerificationResult> verifyClientPin({
    required String phone,
    required String pin,
    bool ensureToken = true,
  }) async {
    if (ensureToken && (_bearerToken == null || _bearerToken!.isEmpty)) {
      await ensureBearerToken(preferAppToken: true);
    }

    final phoneDigits = _requirePhoneDigits(phone);
    if (pin.trim().length < 4) {
      throw PeyapayApiException(message: 'Code PIN invalide');
    }

    final encryptedData = await _encryptDataPayload(
      {
        'gsmPrincipale': phoneDigits,
        'codePin': pin.trim(),
      },
      plainKeys: const {},
    );

    return _postForItem(
      '/wClients/verifCodePin',
      data: encryptedData,
      parser: PeyapayPinVerificationResult.fromJson,
      errorMessage: 'Code PIN PeyaPay incorrect',
      allowEmptyItem: true,
    );
  }
Future<PeyapayClientState> fetchClientState({
    required String phone,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
  }) async {
    final phoneDigits = _requirePhoneDigits(phone);
    final deviceInfo = await PeyapayDeviceInfo.getDeviceInfo();
    final imei = deviceInfo['imei']?.trim() ?? '';
    if (imei.isEmpty || imei == 'unknown') {
      throw PeyapayApiException(message: 'IMEI appareil indisponible pour identifiantPush');
    }

    final encryptedData = await _encryptDataPayload(
      {
        'gsmPrincipale': phoneDigits,
        'codePaysResidence': residenceCountry,
        'identifiantPush': imei,
        'imei': imei,
        'modele': deviceInfo['modele'] ?? 'Unknown Device',
        'plateform': deviceInfo['plateform'] ?? 'unknown',
      },
      plainKeys: {'codePaysResidence'},
    );

    final state = await _postForItem(
      '/wClients/etatclient',
      data: encryptedData,
      parser: PeyapayClientState.fromJson,
      errorMessage: 'Impossible de récupérer l\'état client PeyaPay',
    );

    _clientState = state;
    return state;
  }

  /// Wallet balance via `/wClients/solde` (encrypted `gsmPrincipale` + `codePaysResidence`).
  Future<PeyapayWalletBalance> fetchWalletBalance({
    required String phone,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
    bool ensureToken = true,
  }) async {
    if (ensureToken && (_bearerToken == null || _bearerToken!.isEmpty)) {
      await ensureBearerToken();
    }

    final phoneDigits = _requirePhoneDigits(phone);
    final encryptedData = await _encryptDataPayload(
      {
        'gsmPrincipale': phoneDigits,
        'codePaysResidence': residenceCountry,
      },
      plainKeys: const {},
    );

    final item = await _postForItem<Map<String, dynamic>>(
      '/wClients/solde',
      data: encryptedData,
      parser: (json) => json,
      errorMessage: 'Impossible de récupérer le solde PeyaPay',
    );

    final balance = await PeyapayWalletBalance.fromApiJson(item, crypto: _crypto);
    _walletBalance = balance;
    return balance;
  }

  /// Loads balance via `/wClients/solde`, falling back to `/wClients/cnx` when PIN is available.
  Future<PeyapayWalletBalance> refreshWalletBalance({
    required String phone,
    String? pin,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
    bool ensureToken = true,
  }) async {
    PeyapayWalletBalance? best;

    try {
      final fromSolde = await fetchWalletBalance(
        phone: phone,
        residenceCountry: residenceCountry,
        ensureToken: ensureToken,
      );
      best = fromSolde;
      if (fromSolde.solde != null) return fromSolde;
    } on PeyapayApiException {
      // Try /wClients/cnx below when PIN is available.
    }

    final pinValue = pin?.trim() ?? '';
    if (pinValue.length >= 4) {
      try {
        final cnx = await connectClientWallet(
          phone: phone,
          pin: pinValue,
          residenceCountry: residenceCountry,
          ensureToken: ensureToken,
        );
        final fromCnx = await PeyapayWalletBalance.fromApiJson(
          {
            'gsmPrincipale': cnx.gsmPrincipale,
            'codePaysResidence': cnx.codePaysResidence,
            'solde': cnx.solde,
          },
          crypto: _crypto,
        );
        if (fromCnx.solde != null) {
          _walletBalance = fromCnx;
          return fromCnx;
        }
        best ??= fromCnx;
      } on PeyapayApiException {
        // Keep best from /solde if any.
      }
    }

    if (best != null) {
      _walletBalance = best;
      return best;
    }

    throw PeyapayApiException(message: 'Solde PeyaPay indisponible');
  }

  /// Client-to-client transfer via `/wClients/transfertClient`.
  Future<PeyapayClientTransferResult> transferToClient({
    required String senderPhone,
    required String recipientPhone,
    required int amountReceived,
    int fee = 0,
    String residenceCountry = PeyapayApiConfig.defaultResidenceCountry,
    String codeAgence = PeyapayApiConfig.defaultAgenceCode,
    bool ensureToken = true,
  }) async {
    if (amountReceived <= 0) {
      throw PeyapayApiException(message: 'Montant invalide');
    }

    if (ensureToken && (_bearerToken == null || _bearerToken!.isEmpty)) {
      await ensureBearerToken(preferAppToken: true);
    }

    final senderDigits = _requirePhoneDigits(senderPhone);
    final recipientDigits = _requirePhoneDigits(recipientPhone);
    final amountSent = amountReceived + fee;
    if (amountSent <= 0) {
      throw PeyapayApiException(message: 'Montant envoyé invalide');
    }

  
    final deviceInfo = await PeyapayDeviceInfo.getDeviceInfo();
    final platform = deviceInfo['plateform']?.trim() ?? 'unknown';

    final encryptedData = await _encryptDataPayload(
      {
        'gsmPrincipale': senderDigits,
        'codePaysResidence': residenceCountry,
        'montantEnvoye': amountSent.toString(),
        'montantRecu': amountReceived.toString(),
        'mobileDestinataire': recipientDigits,
        'codeAgence': codeAgence,
        'plateform': platform,
      },
      plainKeys: {
        'codePaysResidence',
        'montantEnvoye',
        'montantRecu',
        'codeAgence',
      },
    );

    final item = await _postForItem(
      '/wClients/transfertClient',
      data: encryptedData,
      parser: PeyapayClientTransferResult.fromJson,
      errorMessage: 'Impossible d\'effectuer le transfert PeyaPay',
      allowEmptyItem: true,
    );

    _walletBalance = null;
    return item;
  }

  /// Account statement via `/vMvtopMvtc/mvtsComptes`.
  Future<PeyapayAccountMovementsPage> fetchAccountMovements({
    required String accountNumber,
    int index = 0,
    int size = 20,
    DateTime? startDate,
    DateTime? endDate,
    bool ensureToken = true,
  }) async {
    if (ensureToken && (_bearerToken == null || _bearerToken!.isEmpty)) {
      await ensureBearerToken(preferAppToken: true);
    }

    final account = accountNumber.trim();
    if (account.isEmpty) {
      throw PeyapayApiException(message: 'Numéro de compte PeyaPay indisponible');
    }

    final now = DateTime.now();
    final rangeStart = startDate ?? DateTime(now.year, 1, 1);
    final rangeEnd = endDate ?? now;

    final encryptedAccount = await _crypto.encryptForApi(
      account,
      label: 'numerocomptecomplet',
    );

    final body = {
      'index': index,
      'size': size,
      'data': {
        'numerocomptecomplet': encryptedAccount,
        'dateOperationParam': {
          'operator': '[]',
          'start': _formatFrApiDate(rangeStart),
          'end': _formatFrApiDate(rangeEnd),
        },
      },
    };

    final envelope = await _postMvtsComptesEnvelope(body);
    final movements = envelope.items ?? const <PeyapayAccountMovement>[];

    return PeyapayAccountMovementsPage(
      movements: movements,
      totalCount: envelope.count,
    );
  }

  /// Resolves the wallet account number used by `/vMvtopMvtc/mvtsComptes`.
  String? resolveWalletAccountNumber({String? phone}) {
    final fromState = _clientState?.accountId?.trim();
    if (fromState != null && fromState.isNotEmpty) return fromState;

    final gsm = _clientState?.gsmPrincipale?.trim();
    if (gsm != null && gsm.isNotEmpty) return gsm.replaceAll(RegExp(r'[^0-9]'), '');

    final phoneDigits = phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (phoneDigits.length == 10) return phoneDigits;

    return null;
  }

  String _requirePhoneDigits(String phone) {
    final phoneDigits = normalizePeyapayPhone(phone);
    if (phoneDigits.length != 10) {
      throw PeyapayApiException(message: 'Numéro de téléphone invalide (10 chiffres attendus)');
    }
    return phoneDigits;
  }

  Future<PeyapayAuthToken> _fetchClientToken({
    required String username,
    required String password,
    required String residenceCountry,
  }) async {
    final response = await _client
        .post(
          _uri(PeyapayApiConfig.tokenEndpoint),
          headers: _jsonHeaders(),
          body: jsonEncode({
            'username': username,
            'password': password,
            'codePaysResidence': residenceCountry,
          }),
        )
        .timeout(PeyapayApiConfig.apiTimeout);

    final token = _parseAuthToken(response);
    _bearerToken = token.token;
    return token;
  }

  Future<Map<String, dynamic>> _encryptDataPayload(
    Map<String, dynamic> plain, {
    required Set<String> plainKeys,
  }) async {
    final encrypted = <String, dynamic>{};
    for (final entry in plain.entries) {
      if (plainKeys.contains(entry.key)) {
        encrypted[entry.key] = entry.value;
        continue;
      }

      final value = entry.value?.toString() ?? '';
      encrypted[entry.key] = await _crypto.encryptForApi(value, label: entry.key);
    }
    return encrypted;
  }

  Future<PeyapayApiEnvelope<Map<String, dynamic>>> _postEnvelope(
    String path, {
    required Map<String, dynamic> data,
    required String errorMessage,
    bool noEncrypt = false,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _jsonHeaders(withBearer: true, noEncrypt: noEncrypt),
          body: jsonEncode({'data': data}),
        )
        .timeout(PeyapayApiConfig.apiTimeout);

    return _parseEnvelope(response, errorMessage: errorMessage);
  }

  Future<PeyapayApiEnvelope<PeyapayAccountMovement>> _postMvtsComptesEnvelope(
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(
          _uri('/vMvtopMvtc/mvtsComptes'),
          headers: _jsonHeaders(withBearer: true, noEncrypt: true),
          body: jsonEncode(body),
        )
        .timeout(PeyapayApiConfig.apiTimeout);

    return _parseItemsEnvelope(
      response,
      errorMessage: 'Impossible de récupérer l\'historique PeyaPay',
      parser: PeyapayAccountMovement.fromJson,
    );
  }

  PeyapayApiEnvelope<T> _parseItemsEnvelope<T>(
    http.Response response, {
    required String errorMessage,
    required T Function(Map<String, dynamic> json) parser,
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw PeyapayApiException(
        message: '$errorMessage (réponse invalide)',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PeyapayApiException.fromResponse(response.statusCode, decoded);
    }

    if (decoded is! Map<String, dynamic>) {
      throw PeyapayApiException(
        message: '$errorMessage (format inattendu)',
        statusCode: response.statusCode,
      );
    }

    final envelope = PeyapayApiEnvelope<T>.fromJson(decoded, parser);
    final code = envelope.code;

    if (envelope.hasError) {
      throw PeyapayApiException(
        message: envelope.message ?? errorMessage,
        statusCode: response.statusCode,
        apiCode: code,
      );
    }

    if (code != null && code.isNotEmpty && code != '800') {
      throw PeyapayApiException(
        message: envelope.message ?? errorMessage,
        statusCode: response.statusCode,
        apiCode: code,
      );
    }

    return envelope;
  }

  static String _formatFrApiDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  Future<void> _postSuccess(
    String path, {
    required Map<String, dynamic> data,
    required String errorMessage,
  }) async {
    await _postEnvelope(path, data: data, errorMessage: errorMessage);
  }

  Future<T> _postForItem<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) parser,
    required String errorMessage,
    bool allowEmptyItem = false,
  }) async {
    final envelope = await _postEnvelope(path, data: data, errorMessage: errorMessage);
    final item = envelope.item;
    if (item == null) {
      if (allowEmptyItem) {
        return parser(const {});
      }
      throw PeyapayApiException(
        message: '$errorMessage (item absent)',
        apiCode: envelope.code,
      );
    }
    return parser(item);
  }

  PeyapayApiEnvelope<Map<String, dynamic>> _parseEnvelope(
    http.Response response, {
    required String errorMessage,
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw PeyapayApiException(
        message: '$errorMessage (réponse invalide)',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PeyapayApiException.fromResponse(response.statusCode, decoded);
    }

    if (decoded is! Map<String, dynamic>) {
      throw PeyapayApiException(
        message: '$errorMessage (format inattendu)',
        statusCode: response.statusCode,
      );
    }

    final envelope = PeyapayApiEnvelope<Map<String, dynamic>>.fromJson(
      decoded,
      (json) => json,
    );

    if (envelope.hasError || envelope.code != '800') {
      throw PeyapayApiException(
        message: envelope.message ?? errorMessage,
        statusCode: response.statusCode,
        apiCode: envelope.code,
      );
    }

    return envelope;
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${PeyapayApiConfig.baseUrl}$normalized');
  }

  Map<String, String> _jsonHeaders({bool withBearer = false, bool noEncrypt = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (noEncrypt) {
      headers['no-encrypt'] = 'true';
    }
    if (withBearer) {
      final token = _bearerToken;
      if (token == null || token.isEmpty) {
        throw PeyapayApiException(message: 'Token PeyaPay absent');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  PeyapayAuthToken _parseAuthToken(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw PeyapayApiException(
        message: 'Réponse auth invalide (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PeyapayApiException.fromResponse(response.statusCode, decoded);
    }

    if (decoded is! Map<String, dynamic>) {
      throw PeyapayApiException(
        message: 'Format de réponse auth inattendu',
        statusCode: response.statusCode,
      );
    }

    final envelope = PeyapayApiEnvelope<PeyapayAuthToken>.fromJson(
      decoded,
      PeyapayAuthToken.fromJson,
    );

    if (envelope.hasError || envelope.code != '800') {
      throw PeyapayApiException(
        message: envelope.message ?? 'Authentification PeyaPay refusée',
        statusCode: response.statusCode,
        apiCode: envelope.code,
      );
    }

    final token = envelope.item ?? _extractLegacyToken(decoded);
    if (token == null || token.token.isEmpty) {
      throw PeyapayApiException(
        message: 'Token JWT absent dans la réponse',
        statusCode: response.statusCode,
      );
    }

    return token;
  }

  PeyapayAuthToken? _extractLegacyToken(Map<String, dynamic> json) {
    final item = json['item'];
    if (item is Map<String, dynamic>) {
      return PeyapayAuthToken.fromJson(item);
    }
    final token = json['token'] ?? json['access_token'] ?? json['accessToken'];
    if (token == null) return null;
    return PeyapayAuthToken(token: token.toString());
  }
}
