import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:peyapay/src/core/config/peyapay_env.registry.dart';
import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/data/models/peyapay_api.exception.dart';
import 'package:peyapay/src/data/models/peyapay_api_envelope.model.dart';
import 'package:peyapay/src/data/models/peyapay_carte.models.dart';

/// Mon Peya backend proxy for Peya Carte client-order flow (`/v1/carte/*`).
class PeyapayCarteApiService {
  PeyapayCarteApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 30);

  final http.Client _client;

  Future<PeyapayCarteMontant> montant() async {
    final envelope = await _post('/v1/carte/montant', const {});
    return PeyapayCarteMontant.fromJson(_requireItem(envelope, 'Prix carte indisponible'));
  }

  Future<PeyapayCarteCurrent> current() async {
    final envelope = await _post('/v1/carte/current', const {});
    return PeyapayCarteCurrent.fromJson(_requireItem(envelope, 'Statut carte indisponible'));
  }

  Future<PeyapayApiEnvelope<PeyapayCarteCurrent>> buy({
    required int idwVilleLivrer,
    required int idwCommuneLivrer,
    Map<String, dynamic> kycFields = const {},
  }) async {
    final data = <String, dynamic>{
      'idwVilleLivrer': idwVilleLivrer,
      'idwCommuneLivrer': idwCommuneLivrer,
      ...kycFields,
    };
    return _postEnvelope('/v1/carte/buy', data, PeyapayCarteCurrent.fromJson);
  }

  Future<PeyapayCarteCurrent> shippingCode() async {
    final envelope = await _post('/v1/carte/shipping/code', const {});
    return PeyapayCarteCurrent.fromJson(_requireItem(envelope, 'Code livraison indisponible'));
  }

  Future<PeyapayCarteBalance> balance() async {
    final envelope = await _post('/v1/carte/balance', const {});
    return PeyapayCarteBalance.fromJson(_requireItem(envelope, 'Solde carte indisponible'));
  }

  Future<Map<String, dynamic>> transactions({
    required String startDate,
    required String endDate,
    int page = 1,
    int size = 50,
  }) async {
    final envelope = await _post('/v1/carte/transactions', {
      'startDate': startDate,
      'endDate': endDate,
      'page': page,
      'size': size,
    });
    return _requireItem(envelope, 'Historique carte indisponible');
  }

  Future<PeyapayCarteCurrent> inactive() async {
    final envelope = await _post('/v1/carte/inactive', const {});
    return PeyapayCarteCurrent.fromJson(_requireItem(envelope, 'Gel carte impossible'));
  }

  Future<PeyapayCarteCurrent> activate() async {
    final envelope = await _post('/v1/carte/activate', const {});
    return PeyapayCarteCurrent.fromJson(_requireItem(envelope, 'Activation carte impossible'));
  }

  Future<List<PeyapayCarteLocation>> villes({int index = 0, int size = 200}) async {
    final envelope = await _postPaged('/v1/carte/villes', const {}, index: index, size: size);
    return _parseLocations(envelope);
  }

  Future<List<PeyapayCarteLocation>> communes({
    required int idWVille,
    int index = 0,
    int size = 200,
  }) async {
    final envelope = await _postPaged(
      '/v1/carte/communes',
      {'idWVille': idWVille},
      index: index,
      size: size,
    );
    return _parseLocations(envelope);
  }

  Future<PeyapayApiEnvelope<Map<String, dynamic>>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    return _postEnvelope(path, data, (json) => json);
  }

  Future<PeyapayApiEnvelope<T>> _postEnvelope<T>(
    String path,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic> json) parser,
  ) async {
    try {
      final token = await _requireAccessToken();
      final response = await _client
          .post(
            _uri(path),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'data': {'accessToken': token, ...data},
            }),
          )
          .timeout(_timeout);

      final decoded = _decodeBody(response);
      final envelope = PeyapayApiEnvelope.fromJson(decoded, parser);

      if (response.statusCode == 401) {
        throw PeyapayApiException(
          message: envelope.message ?? 'Session Mon Peya expirée',
          statusCode: 401,
          apiCode: envelope.code ?? '901',
        );
      }

      if (response.statusCode >= 500) {
        throw PeyapayApiException(
          message: 'Serveur Mon Peya indisponible',
          statusCode: response.statusCode,
          apiCode: envelope.code,
        );
      }

      return envelope;
    } on PeyapayApiException {
      rethrow;
    } on TimeoutException {
      throw PeyapayApiException(message: 'Le serveur Mon Peya ne répond pas (${_baseUrl})');
    } on SocketException {
      throw PeyapayApiException(
        message: 'Impossible de joindre Mon Peya ($_baseUrl). Vérifiez le backend.',
      );
    } catch (e) {
      throw PeyapayApiException(message: 'Appel carte impossible ($e)');
    }
  }

  Future<PeyapayApiEnvelope<Map<String, dynamic>>> _postPaged(
    String path,
    Map<String, dynamic> data, {
    required int index,
    required int size,
  }) async {
    try {
      final token = await _requireAccessToken();
      final response = await _client
          .post(
            _uri(path),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'data': {'accessToken': token, ...data},
              'index': index,
              'size': size,
            }),
          )
          .timeout(_timeout);
      final decoded = _decodeBody(response);
      return PeyapayApiEnvelope.fromJson(decoded, (json) => json);
    } on PeyapayApiException {
      rethrow;
    } catch (e) {
      throw PeyapayApiException(message: 'Référentiel livraison indisponible ($e)');
    }
  }

  Map<String, dynamic> _requireItem(
    PeyapayApiEnvelope<Map<String, dynamic>> envelope,
    String fallback,
  ) {
    if (envelope.hasError) {
      throw PeyapayApiException(
        message: envelope.message ?? fallback,
        apiCode: envelope.code,
      );
    }
    final item = envelope.item;
    if (item == null) {
      throw PeyapayApiException(message: '$fallback (réponse vide)');
    }
    return item;
  }

  List<PeyapayCarteLocation> _parseLocations(PeyapayApiEnvelope<Map<String, dynamic>> envelope) {
    if (envelope.hasError) {
      throw PeyapayApiException(
        message: envelope.message ?? 'Référentiel indisponible',
        apiCode: envelope.code,
      );
    }
    final fromItems = envelope.items;
    if (fromItems != null && fromItems.isNotEmpty) {
      return fromItems
          .map(PeyapayCarteLocation.fromJson)
          .where((e) => e.id > 0)
          .toList(growable: false);
    }
    final item = envelope.item;
    if (item != null && item.isNotEmpty) {
      return [PeyapayCarteLocation.fromJson(item)].where((e) => e.id > 0).toList();
    }
    return const [];
  }

  Future<String> _requireAccessToken() async {
    final token = await PeyapayHostBridge.requireAuth.monPeyaAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw PeyapayApiException(
        message: 'Connectez-vous à Mon Peya pour commander ou gérer votre carte.',
        apiCode: '901',
      );
    }
    return token.trim();
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw PeyapayApiException(message: 'Réponse Mon Peya invalide');
    }
    return decoded;
  }

  String get _baseUrl {
    final url = PeyapayEnvRegistry.monPeyaApiUrl;
    if (url == null || url.isEmpty) {
      throw PeyapayApiException(message: 'URL backend Mon Peya non configurée');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalized');
  }
}
