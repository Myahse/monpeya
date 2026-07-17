import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:leadway/src/core/constants/leadway_life.constants.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_life_cotation_request.model.dart';
import 'package:leadway/src/data/models/leadway_life_cotation_response.model.dart';
import 'package:leadway/src/data/models/leadway_life_list.model.dart';
import 'package:leadway/src/data/models/leadway_life_payment.model.dart';
import 'package:leadway/src/data/models/leadway_life_subscription.model.dart';
import 'package:leadway/src/data/services/leadway_api.service.dart';

/// Config dédiée à l'API Assurance Vie Leadway.
class LeadwayLifeApiConfig {
  static const defaultBaseUrl = String.fromEnvironment(
    'LEADWAY_LIFE_API_URL',
    defaultValue: 'https://lv-test.djogana-pay.com:9290',
  );

  static String get baseUrl => defaultBaseUrl;

  static bool get useMock => LeadwayApiConfig.useMock;
}

/// Compteur de polling mock pour check-paiement.
final Map<String, int> _lifeCheckAttempts = {};

HttpClient _lifeUnsafeHttpClient() {
  final client = HttpClient();
  client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return client;
}

/// Client HTTP pour l'API Vie (`/api/souscription/*`, `/api/enums/*`).
class LeadwayLifeApiService {
  LeadwayLifeApiService({http.Client? client})
      : _client = client ?? IOClient(_lifeUnsafeHttpClient());

  final http.Client _client;

  Future<List<LeadwayLifeEnumItem>> fetchRelationships() =>
      _fetchEnums('/api/enums/relationship');

  Future<List<LeadwayLifeEnumItem>> fetchPaymentFrequencies() =>
      _fetchEnums('/api/enums/frequence-paiement');

  Future<List<LeadwayLifeEnumItem>> fetchProductCodes() =>
      _fetchEnums('/api/enums/code-produit');

  Future<List<LeadwayLifeEnumItem>> _fetchEnums(String path) async {
    final url = '${LeadwayLifeApiConfig.baseUrl}$path';
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateEnums(path);
    }

    try {
      print('--> GET $url');
      final response = await _client
          .get(
            Uri.parse(url),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      print('<-- ${response.statusCode} $url');
      print('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse enums invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => LeadwayLifeEnumItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        throw const LeadwayApiException(message: 'Format enums inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] enums failed: $e — fallback simulation');
        return _simulateEnums(path);
      }
      rethrow;
    }
  }

  /// POST /api/souscription/cotation
  Future<LeadwayLifeCotationResult> calculateCotation(LeadwayLifeCotationRequest request) async {
    final url = '${LeadwayLifeApiConfig.baseUrl}/api/souscription/cotation';
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateCotation(url, request);
    }

    try {
      final body = jsonEncode(request.toJson());
      print('--> POST $url');
      print('Request Body: $body');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('<-- ${response.statusCode} $url');
      print('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse cotation Vie invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return LeadwayLifeCotationResult.fromJson(decoded);
        }
        if (decoded is Map) {
          return LeadwayLifeCotationResult.fromJson(Map<String, dynamic>.from(decoded));
        }
        throw const LeadwayApiException(message: 'Format cotation Vie inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] cotation failed: $e — fallback simulation');
        return _simulateCotation(url, request);
      }
      rethrow;
    }
  }

  /// POST /api/souscription
  Future<LeadwayLifeSubscriptionResult> createSubscription(
    LeadwayLifeSubscriptionRequest request,
  ) async {
    final url = '${LeadwayLifeApiConfig.baseUrl}/api/souscription';
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateSubscription(url, request);
    }

    try {
      final body = jsonEncode(request.toJson());
      print('--> POST $url');
      print('Request Body: $body');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('<-- ${response.statusCode} $url');
      print('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse souscription Vie invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return LeadwayLifeSubscriptionResult.fromJson(decoded);
        }
        if (decoded is Map) {
          return LeadwayLifeSubscriptionResult.fromJson(Map<String, dynamic>.from(decoded));
        }
        throw const LeadwayApiException(message: 'Format souscription Vie inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] souscription failed: $e — fallback simulation');
        return _simulateSubscription(url, request);
      }
      rethrow;
    }
  }

  /// POST /api/souscription/{reference}/paiement
  Future<LeadwayLifePaymentResult> initiatePayment({
    required String subscriptionRef,
    required LeadwayLifePaymentRequest request,
  }) async {
    final url = '${LeadwayLifeApiConfig.baseUrl}/api/souscription/$subscriptionRef/paiement';
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateLifePayment(url, subscriptionRef, request);
    }

    try {
      final body = jsonEncode(request.toJson());
      print('--> POST $url');
      print('Request Body: $body');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('<-- ${response.statusCode} $url');
      print('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse paiement Vie invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return LeadwayLifePaymentResult.fromJson(decoded);
        }
        if (decoded is Map) {
          return LeadwayLifePaymentResult.fromJson(Map<String, dynamic>.from(decoded));
        }
        throw const LeadwayApiException(message: 'Format paiement Vie inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] paiement failed: $e — fallback simulation');
        return _simulateLifePayment(url, subscriptionRef, request);
      }
      rethrow;
    }
  }

  /// POST /api/souscription/check-paiement
  Future<LeadwayLifePaymentCheckResult> checkPayment(LeadwayLifePaymentCheckRequest request) async {
    final url = '${LeadwayLifeApiConfig.baseUrl}/api/souscription/check-paiement';
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateLifeCheckPayment(url, request);
    }

    try {
      final body = jsonEncode(request.toJson());
      print('--> POST $url');
      print('Request Body: $body');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      print('<-- ${response.statusCode} $url');
      print('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse check-paiement Vie invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return LeadwayLifePaymentCheckResult.fromJson(decoded);
        }
        if (decoded is Map) {
          return LeadwayLifePaymentCheckResult.fromJson(Map<String, dynamic>.from(decoded));
        }
        throw const LeadwayApiException(message: 'Format check-paiement Vie inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] check-paiement failed: $e — fallback simulation');
        return _simulateLifeCheckPayment(url, request);
      }
      rethrow;
    }
  }

  /// GET /api/souscription — liste paginée
  Future<LeadwayLifeSubscriptionListResult> listSubscriptions({
    required String customerId,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final uri = Uri.parse('${LeadwayLifeApiConfig.baseUrl}/api/souscription').replace(
      queryParameters: {
        'customerId': customerId,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': '$page',
        'size': '$size',
      },
    );
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateListSubscriptions(uri.toString(), customerId, status, page, size);
    }

    try {
      print('--> GET $uri');
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      print('<-- ${response.statusCode} $uri');
      print('Response Body: ${response.body}');

      final decoded = _decodeJsonMap(response.body, response.statusCode, 'liste souscriptions');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LeadwayLifeSubscriptionListResult.fromJson(decoded);
      }
      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] listSubscriptions failed: $e — fallback simulation');
        return _simulateListSubscriptions(uri.toString(), customerId, status, page, size);
      }
      rethrow;
    }
  }

  /// GET /api/souscription/{reference}
  Future<LeadwayLifeSubscriptionResult> getSubscription(String reference) async {
    final url = '${LeadwayLifeApiConfig.baseUrl}/api/souscription/$reference';
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateGetSubscription(url, reference);
    }

    try {
      print('--> GET $url');
      final response = await _client
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      print('<-- ${response.statusCode} $url');
      print('Response Body: ${response.body}');

      final decoded = _decodeJsonMap(response.body, response.statusCode, 'détail souscription');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LeadwayLifeSubscriptionResult.fromJson(decoded);
      }
      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] getSubscription failed: $e — fallback simulation');
        return _simulateGetSubscription(url, reference);
      }
      rethrow;
    }
  }

  /// GET /api/souscription/{reference}/issue
  Future<LeadwayLifeIssueResult> getIssueStatus(String reference) async {
    final url = '${LeadwayLifeApiConfig.baseUrl}/api/souscription/$reference/issue';
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateIssueStatus(url, reference);
    }

    try {
      print('--> GET $url');
      final response = await _client
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      print('<-- ${response.statusCode} $url');
      print('Response Body: ${response.body}');

      final decoded = _decodeJsonMap(response.body, response.statusCode, 'statut police');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LeadwayLifeIssueResult.fromJson(decoded);
      }
      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] getIssueStatus failed: $e — fallback simulation');
        return _simulateIssueStatus(url, reference);
      }
      rethrow;
    }
  }

  /// GET /api/souscription/paiement-recurrent
  Future<LeadwayLifeRecurringPaymentListResult> listRecurringPayments({
    String? customerId,
    String? policyNumber,
    String? productCode,
    String? status,
    String? createdFrom,
    String? createdTo,
    int page = 0,
    int size = 10,
  }) async {
    final uri = Uri.parse('${LeadwayLifeApiConfig.baseUrl}/api/souscription/paiement-recurrent').replace(
      queryParameters: {
        if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
        if (policyNumber != null && policyNumber.isNotEmpty) 'policyNumber': policyNumber,
        if (productCode != null && productCode.isNotEmpty) 'productCode': productCode,
        if (status != null && status.isNotEmpty) 'status': status,
        if (createdFrom != null && createdFrom.isNotEmpty) 'createdFrom': createdFrom,
        if (createdTo != null && createdTo.isNotEmpty) 'createdTo': createdTo,
        'page': '$page',
        'size': '$size',
      },
    );
    if (LeadwayLifeApiConfig.useMock) {
      return _simulateRecurringPayments(uri.toString(), page, size, customerId, status);
    }

    try {
      print('--> GET $uri');
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      print('<-- ${response.statusCode} $uri');
      print('Response Body: ${response.body}');

      final decoded = _decodeJsonMap(response.body, response.statusCode, 'paiements récurrents');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LeadwayLifeRecurringPaymentListResult.fromJson(decoded);
      }
      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException) {
        print('⚠️ [LeadwayLifeApi] listRecurringPayments failed: $e — fallback simulation');
        return _simulateRecurringPayments(uri.toString(), page, size, customerId, status);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _decodeJsonMap(String body, int statusCode, String label) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw LeadwayApiException(message: 'Format $label inattendu', statusCode: statusCode);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      throw LeadwayApiException(message: 'Réponse $label invalide ($statusCode)', statusCode: statusCode);
    }
  }

  List<LeadwayLifeEnumItem> _simulateEnums(String path) {
    if (path.contains('relationship')) {
      return LeadwayLifeRelationship.values
          .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
          .toList();
    }
    if (path.contains('frequence')) {
      return LeadwayLifePaymentFrequency.values
          .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
          .toList();
    }
    return LeadwayLifeProductCode.values
        .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
        .toList();
  }

  Future<LeadwayLifeCotationResult> _simulateCotation(
    String url,
    LeadwayLifeCotationRequest request,
  ) async {
    print('--> POST $url (SIMULATION VIE)');
    print('Request Body: ${jsonEncode(request.toJson())}');
    await Future.delayed(const Duration(milliseconds: 900));

    final base = request.tierInputAmount > 0 ? request.tierInputAmount : 5000;
    final net = (base * 0.85).round();
    final tax = base - net;
    final mock = {
      'success': true,
      'data': {
        'subscriptionRef': request.subscriptionRef,
        'productCode': request.productCode,
        'status': 'QUOTED',
        'premium': {
          'gross': {'amount': base, 'currency': 'XOF'},
          'net': {'amount': net, 'currency': 'XOF'},
          'tax': {'amount': tax, 'currency': 'XOF'},
          'frequency': request.paymentFrequency,
          'breakdown': [
            'Prime nette: $net XOF',
            'Taxes: $tax XOF',
            'Prime TTC: $base XOF',
          ],
        },
        'computedAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifeCotationResult.fromJson(mock);
  }

  Future<LeadwayLifeSubscriptionResult> _simulateSubscription(
    String url,
    LeadwayLifeSubscriptionRequest request,
  ) async {
    print('--> POST $url (SIMULATION SOUSCRIPTION VIE)');
    print('Request Body: ${jsonEncode(request.toJson())}');
    await Future.delayed(const Duration(milliseconds: 900));

    final ref = 'SUB-${DateTime.now().millisecondsSinceEpoch}';
    final mock = {
      'success': true,
      'data': {
        'id': 'id-$ref',
        'subscriptionRef': ref,
        'productCode': request.productCode,
        'policyNumber': 'POL-${DateTime.now().millisecondsSinceEpoch % 100000000}',
        'status': 'ACTIVE',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifeSubscriptionResult.fromJson(mock);
  }

  Future<LeadwayLifePaymentResult> _simulateLifePayment(
    String url,
    String subscriptionRef,
    LeadwayLifePaymentRequest request,
  ) async {
    print('--> POST $url (SIMULATION PAIEMENT VIE)');
    print('Request Body: ${jsonEncode(request.toJson())}');
    await Future.delayed(const Duration(milliseconds: 900));

    final tx = 'TX-${DateTime.now().millisecondsSinceEpoch}';
    final isWave = request.method.toUpperCase() == 'WAVE';
    _lifeCheckAttempts[tx] = 0;
    final mock = {
      'success': true,
      'data': {
        'subscriptionRef': subscriptionRef,
        'transactionId': tx,
        'redirectUrl': isWave ? 'https://pay.wave.com/c/$tx' : '',
        'paymentStatus': 'PENDING',
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifePaymentResult.fromJson(mock);
  }

  Future<LeadwayLifePaymentCheckResult> _simulateLifeCheckPayment(
    String url,
    LeadwayLifePaymentCheckRequest request,
  ) async {
    print('--> POST $url (SIMULATION CHECK PAIEMENT VIE)');
    print('Request Body: ${jsonEncode(request.toJson())}');
    await Future.delayed(const Duration(milliseconds: 300));

    final attempts = (_lifeCheckAttempts[request.transactionId] ?? 0) + 1;
    _lifeCheckAttempts[request.transactionId] = attempts;
    final paid = attempts >= 3;
    final now = DateTime.now().toUtc().toIso8601String();
    final mock = {
      'success': true,
      'data': {
        'transactionId': request.transactionId,
        'amount': 15000,
        'currency': 'XOF',
        'status': paid ? 'PAID' : 'PENDING',
        'payerRef': '0707070707',
        'createdAt': now,
        'updatedAt': now,
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifePaymentCheckResult.fromJson(mock);
  }

  Future<LeadwayLifeSubscriptionListResult> _simulateListSubscriptions(
    String url,
    String customerId,
    String? status,
    int page,
    int size,
  ) async {
    print('--> GET $url (SIMULATION LISTE SOUSCRIPTIONS)');
    await Future.delayed(const Duration(milliseconds: 500));

    const totalItems = 28;
    final totalPages = (totalItems / size).ceil();
    final start = page * size;
    final statuses = LeadwayLifeSubscriptionStatus.values;
    final items = <Map<String, dynamic>>[];
    for (var i = start; i < start + size && i < totalItems; i++) {
      final st = status?.isNotEmpty == true ? status! : statuses[i % statuses.length].code;
      items.add({
        'id': 'id-$i',
        'subscriptionRef': 'SUB-LV-${1000 + i}',
        'customerId': customerId,
        'productCode': i.isEven ? 'FUNERAIRES_DJOGANA' : 'BNB_DJOGANA',
        'policyNumber': 'POL-${200000 + i}',
        'premium': {
          'gross': {'amount': 10000 + i * 500, 'currency': 'XOF'},
          'net': {'amount': 8500 + i * 400, 'currency': 'XOF'},
          'tax': {'amount': 1500 + i * 100, 'currency': 'XOF'},
          'frequency': 'MONTHLY',
          'breakdown': ['Prime nette', 'Taxes'],
        },
        'status': st,
        'createdAt': DateTime.now().subtract(Duration(days: i)).toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }

    final mock = {
      'success': true,
      'data': {
        'subscriptions': {
          'items': items,
          'totalItems': totalItems,
          'page': page,
          'pageSize': size,
          'totalPages': totalPages,
        },
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifeSubscriptionListResult.fromJson(mock);
  }

  Future<LeadwayLifeSubscriptionResult> _simulateGetSubscription(String url, String reference) async {
    print('--> GET $url (SIMULATION DÉTAIL SOUSCRIPTION)');
    await Future.delayed(const Duration(milliseconds: 400));
    final mock = {
      'success': true,
      'data': {
        'id': 'id-$reference',
        'subscriptionRef': reference,
        'productCode': 'FUNERAIRES_DJOGANA',
        'policyNumber': 'POL-${reference.hashCode.abs() % 100000000}',
        'status': 'CREATED',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifeSubscriptionResult.fromJson(mock);
  }

  Future<LeadwayLifeIssueResult> _simulateIssueStatus(String url, String reference) async {
    print('--> GET $url (SIMULATION ISSUE POLICE)');
    await Future.delayed(const Duration(milliseconds: 400));
    final mock = {
      'success': true,
      'data': {
        'subscriptionRef': reference,
        'message': 'La police est disponible au téléchargement.',
        'policyStatus': 'ISSUED',
        'status': 'READY',
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifeIssueResult.fromJson(mock);
  }

  Future<LeadwayLifeRecurringPaymentListResult> _simulateRecurringPayments(
    String url,
    int page,
    int size,
    String? customerId,
    String? status,
  ) async {
    print('--> GET $url (SIMULATION PAIEMENTS RÉCURRENTS)');
    await Future.delayed(const Duration(milliseconds: 500));

    const totalItems = 23;
    final totalPages = (totalItems / size).ceil();
    final start = page * size;
    final statuses = LeadwayLifeRecurringPaymentStatus.values;
    final items = <Map<String, dynamic>>[];
    for (var i = start; i < start + size && i < totalItems; i++) {
      final st = status?.isNotEmpty == true ? status! : statuses[i % statuses.length].code;
      final day = DateTime.now().add(Duration(days: i));
      items.add({
        'id': 'rp-$i',
        'customerId': customerId ?? 'CUST-DEMO',
        'productCode': i.isEven ? 'FUNERAIRES_DJOGANA' : 'BNB_DJOGANA',
        'policyNumber': 'POL-${300000 + i}',
        'amount': 5000 + i * 250,
        'currency': 'XOF',
        'paymentMethod': i.isEven ? 'WAVE' : 'ORANGE',
        'frequency': 'MONTHLY',
        'status': st,
        'nextPaymentDate': day.toIso8601String().substring(0, 10),
        'lastPaymentDate': day.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10),
        'createdAt': DateTime.now().subtract(Duration(days: i * 2)).toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }

    final mock = {
      'success': true,
      'data': {
        'items': items,
        'totalItems': totalItems,
        'page': page,
        'pageSize': size,
        'totalPages': totalPages,
      },
    };
    print('<-- 200 $url (SIMULATION)');
    print('Response Body: ${jsonEncode(mock)}');
    return LeadwayLifeRecurringPaymentListResult.fromJson(mock);
  }
}
