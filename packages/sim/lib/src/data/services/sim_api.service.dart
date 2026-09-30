import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sim/src/data/errors/sim_api.exception.dart';
import 'package:sim/src/shared/config/sim_env.registry.dart';
import 'package:sim/src/data/models/sim_catalogue.model.dart';
import 'package:sim/src/data/models/sim_confirm_payment.model.dart';
import 'package:sim/src/data/models/sim_devis.model.dart';
import 'package:sim/src/data/models/sim_ping.model.dart';
import 'package:sim/src/data/models/sim_souscription.model.dart';

class SimApiConfig {
  static const _defineBaseUrl = String.fromEnvironment(
    'SIM_API_BASE_URL',
    defaultValue: 'https://protect.mysimassurances.com/api/partner/v1',
  );

  static const _defineApiKey = String.fromEnvironment('SIM_API_KEY', defaultValue: '');

  static String get baseUrl {
    final runtime = SimEnvRegistry.baseUrl;
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return _defineBaseUrl;
  }

  static String get apiKey {
    final runtime = SimEnvRegistry.apiKey;
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return _defineApiKey;
  }

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}

class SimApiService {
  SimApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (SimApiConfig.apiKey.isNotEmpty) 'Authorization': 'Bearer ${SimApiConfig.apiKey}',
      };

  Uri _uri(String path) => Uri.parse('${SimApiConfig.baseUrl}$path');

  Future<T> _decodeData<T>(
    http.Response response,
    T Function(Map<String, dynamic> data) mapper,
  ) async {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw SimApiException(
        message: 'Réponse invalide (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map && body['data'] is Map) {
        return mapper(Map<String, dynamic>.from(body['data'] as Map));
      }
      if (body is Map && body['data'] is List) {
        throw SimApiException(message: 'Format liste inattendu', statusCode: response.statusCode);
      }
      throw const SimApiException(message: 'Format de réponse inattendu');
    }

    throw SimApiException.fromEnvelope(response.statusCode, body);
  }

  Future<List<T>> _decodeDataList<T>(
    http.Response response,
    T Function(Map<String, dynamic> item) mapper,
  ) async {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw SimApiException(
        message: 'Réponse invalide (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map && body['data'] is List) {
        return (body['data'] as List)
            .whereType<Map>()
            .map((e) => mapper(Map<String, dynamic>.from(e)))
            .toList();
      }
      throw const SimApiException(message: 'Format de liste inattendu');
    }

    throw SimApiException.fromEnvelope(response.statusCode, body);
  }

  Future<SimPingResult> ping() async {
    final response = await _client.get(_uri('/ping'), headers: _headers);
    return _decodeData(response, SimPingResult.fromJson);
  }

  Future<List<SimProduitCatalogue>> catalogue() async {
    final response = await _client.get(_uri('/catalogue'), headers: _headers);
    return _decodeDataList(response, SimProduitCatalogue.fromJson);
  }

  Future<SimDevisResult> devis(SimDevisRequest request) async {
    final response = await _client.post(
      _uri('/devis'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
    return _decodeData(response, SimDevisResult.fromJson);
  }

  Future<SimSouscriptionResult> createSouscription(
    SimSouscriptionRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _client.post(
      _uri('/souscriptions'),
      headers: {..._headers, 'Idempotency-Key': idempotencyKey},
      body: jsonEncode(request.toJson()),
    );
    return _decodeData(response, SimSouscriptionResult.fromJson);
  }

  Future<SimConfirmPaymentResult> confirmPayment(
    String souscriptionId,
    SimConfirmPaymentRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _client.post(
      _uri('/souscriptions/$souscriptionId/confirmer-paiement'),
      headers: {..._headers, 'Idempotency-Key': idempotencyKey},
      body: jsonEncode(request.toJson()),
    );
    return _decodeData(response, SimConfirmPaymentResult.fromJson);
  }

  Future<List<int>> fetchCartePng(String souscriptionId) async {
    final response = await _client.get(
      _uri('/souscriptions/$souscriptionId/carte.png'),
      headers: {
        'Accept': 'image/png',
        if (SimApiConfig.apiKey.isNotEmpty) 'Authorization': 'Bearer ${SimApiConfig.apiKey}',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }
    throw SimApiException.fromEnvelope(response.statusCode, body);
  }
}
