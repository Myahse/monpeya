import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_premium_request.model.dart';
import 'package:leadway/src/data/models/leadway_premium_response.model.dart';
import 'package:leadway/src/data/models/leadway_quote_request.model.dart';
import 'package:leadway/src/data/models/leadway_quote_response.model.dart';
import 'package:leadway/src/data/models/leadway_api_payment_init_request.model.dart';
import 'package:leadway/src/data/models/leadway_api_payment_request.model.dart';
import 'package:leadway/src/data/models/leadway_api_payment_check_request.model.dart';
import 'package:leadway/src/core/constants/leadway_api.constants.dart';

class LeadwayApiConfig {
  static const defaultBaseUrl = String.fromEnvironment(
    'LEADWAY_API_URL',
    defaultValue: 'https://lnv-test.djogana-pay.com:9190',
  );

  /// Configuration pour activer / désactiver le mode mock (simulation réaliste) pour le service Leadway.
  /// Peut être surchargé au démarrage via --dart-define=LEADWAY_USE_MOCK=false
  static bool useMock = const bool.fromEnvironment(
    'LEADWAY_USE_MOCK',
    defaultValue: false,
  );

  /// Active / désactive Peya Pay comme moyen de paiement.
  /// Surchargeable via --dart-define=LEADWAY_ENABLE_PEYAPAY=false
  static bool enablePeyaPay = const bool.fromEnvironment(
    'LEADWAY_ENABLE_PEYAPAY',
    defaultValue: true,
  );

  static String get baseUrl {
    if (defaultBaseUrl.contains('leadway.com')) {
      return 'https://84.8.137.29:9190';
    }
    return defaultBaseUrl;
  }
}

/// Accepts self-signed / IP-only certificates of the Leadway test gateway in
/// debug builds only. Release builds always verify TLS certificates.
HttpClient leadwayHttpClient() {
  final client = HttpClient();
  if (kDebugMode) {
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
  return client;
}

/// Debug-only logging: request/response bodies carry customer data.
void leadwayLog(String message) {
  if (kDebugMode) debugPrint(message);
}

/// Connectivity / TLS failures. In debug builds callers fall back to simulated
/// responses; release builds throw [LeadwayApiException.unreachable] so a
/// failed payment is never reported as successful.
bool isLeadwayNetworkError(Object e) =>
    e is SocketException || e is HttpException || e is TimeoutException || e is HandshakeException;

class LeadwayApiService {
  LeadwayApiService({http.Client? client}) : _client = client ?? IOClient(leadwayHttpClient());

  final http.Client _client;

  /// Activez cette option pour simuler intégralement et de façon très réaliste
  /// tout le parcours Leadway (calcul, devis, paiement, statut) sans nécessiter la passerelle.
  static bool get useSimulation => LeadwayApiConfig.useMock;
  static set useSimulation(bool value) => LeadwayApiConfig.useMock = value;

  /// Stockage en mémoire du nombre de tentatives de vérification par paymentId
  /// pour simuler une attente réaliste (1er check en cours, 2e check succès).
  static final Map<String, int> _checkAttempts = {};

  /// POST /api/auto/calcule-prime
  Future<LeadwayPremiumResult> calculatePremium(LeadwayPremiumRequest request) async {
    final url = '${LeadwayApiConfig.baseUrl}/api/auto/calcule-prime';
    if (useSimulation) {
      return _simulateCalculatePremium(url, request);
    }

    try {
      final requestBody = jsonEncode(request.toJson());
      
      leadwayLog('--> POST $url');
      leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
      leadwayLog('Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 20));

      leadwayLog('<-- ${response.statusCode} $url');
      leadwayLog('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse invalide du serveur Leadway (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return LeadwayPremiumResult.fromJson(decoded);
        }
        throw const LeadwayApiException(message: 'Format de réponse inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (isLeadwayNetworkError(e)) {
        if (!kDebugMode) throw LeadwayApiException.unreachable;
        leadwayLog('[LeadwayApiService] Connection failed: $e. Falling back to realistic simulation...');
        return _simulateCalculatePremium(url, request);
      }
      rethrow;
    }
  }

  /// POST /api/auto/devis
  Future<LeadwayQuoteResponse> createQuote(LeadwayQuoteRequest request) async {
    final url = '${LeadwayApiConfig.baseUrl}/api/auto/devis';
    if (useSimulation) {
      return _simulateCreateQuote(url, request);
    }

    try {
      final requestBody = jsonEncode(request.toJson());

      leadwayLog('--> POST $url');
      leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
      leadwayLog('Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 20));

      leadwayLog('<-- ${response.statusCode} $url');
      leadwayLog('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse devis invalide du serveur Leadway (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return LeadwayQuoteResponse.fromJson(decoded);
        }
        throw const LeadwayApiException(message: 'Format de réponse devis inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (isLeadwayNetworkError(e)) {
        if (!kDebugMode) throw LeadwayApiException.unreachable;
        leadwayLog('[LeadwayApiService] Connection failed: $e. Falling back to realistic simulation...');
        return _simulateCreateQuote(url, request);
      }
      rethrow;
    }
  }

  /// POST /api/auto/paiement — étape 1 : initier le paiement.
  Future<Map<String, dynamic>> initPayment(LeadwayApiPaymentInitRequest request) async {
    final url = '${LeadwayApiConfig.baseUrl}/api/auto/paiement';
    if (useSimulation) {
      return _simulateInitPayment(url, request);
    }

    try {
      final requestBody = jsonEncode(request.toJson());

      leadwayLog('--> POST $url');
      leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
      leadwayLog('Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 20));

      leadwayLog('<-- ${response.statusCode} $url');
      leadwayLog('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse initiation paiement invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          leadwayLog('[Leadway] Init paiement — réponse (${response.statusCode}): ${jsonEncode(decoded)}');
          return decoded;
        }
        throw const LeadwayApiException(message: 'Format de réponse initiation paiement inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (isLeadwayNetworkError(e)) {
        if (!kDebugMode) throw LeadwayApiException.unreachable;
        leadwayLog('[LeadwayApiService] Connection failed: $e. Falling back to realistic simulation...');
        return _simulateInitPayment(url, request);
      }
      rethrow;
    }
  }

  /// POST /api/auto/paiement-pay — étape 2 : confirmer le paiement.
  Future<Map<String, dynamic>> confirmPayment(LeadwayApiPaymentRequest request) async {
    final url = '${LeadwayApiConfig.baseUrl}/api/auto/paiement-pay';
    if (useSimulation) {
      return _simulateConfirmPayment(url, request);
    }

    try {
      final requestBody = jsonEncode(request.toJson());

      leadwayLog('--> POST $url');
      leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
      leadwayLog('Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 20));

      leadwayLog('<-- ${response.statusCode} $url');
      leadwayLog('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse confirmation paiement invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw const LeadwayApiException(message: 'Format de réponse confirmation paiement inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (isLeadwayNetworkError(e)) {
        if (!kDebugMode) throw LeadwayApiException.unreachable;
        leadwayLog('[LeadwayApiService] Connection failed: $e. Falling back to realistic simulation...');
        return _simulateConfirmPayment(url, request);
      }
      rethrow;
    }
  }

  /// Alias conservé pour compatibilité interne.
  Future<Map<String, dynamic>> initiatePayment(LeadwayApiPaymentRequest request) =>
      confirmPayment(request);

  /// POST /api/auto/paiement-check — étape 3 : vérifier le statut du paiement.
  Future<Map<String, dynamic>> checkPaymentStatus(LeadwayApiPaymentCheckRequest request) async {
    final url = '${LeadwayApiConfig.baseUrl}/api/auto/paiement-check';
    if (useSimulation) {
      return _simulateCheckPaymentStatus(url, request);
    }

    try {
      final requestBody = jsonEncode(request.toJson());

      leadwayLog('--> POST $url');
      leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
      leadwayLog('Request Body: $requestBody');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 20));

      leadwayLog('<-- ${response.statusCode} $url');
      leadwayLog('Response Body: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw LeadwayApiException(
          message: 'Réponse vérification paiement invalide (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw const LeadwayApiException(message: 'Format de réponse vérification inattendu');
      }

      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (isLeadwayNetworkError(e)) {
        if (!kDebugMode) throw LeadwayApiException.unreachable;
        leadwayLog('[LeadwayApiService] Connection failed: $e. Falling back to realistic simulation...');
        return _simulateCheckPaymentStatus(url, request);
      }
      rethrow;
    }
  }

  /// GET /api/auto/contrat/pdf/{policyNo}
  Future<Uint8List> downloadContractPdf(String policyNo) async {
    final url = '${LeadwayApiConfig.baseUrl}/api/auto/contrat/pdf/$policyNo';
    return _downloadPdf(url, 'contrat', policyNo);
  }

  /// GET /api/auto/devis/pdf/{policyNo}
  Future<Uint8List> downloadQuotePdf(String policyNo) async {
    final url = '${LeadwayApiConfig.baseUrl}/api/auto/devis/pdf/$policyNo';
    return _downloadPdf(url, 'devis', policyNo);
  }

  Future<Uint8List> _downloadPdf(String url, String label, String policyNo) async {
    if (useSimulation) {
      return _simulateDownloadPdf(url, label, policyNo);
    }

    try {
      leadwayLog('--> GET $url');
      final response = await _client
          .get(
            Uri.parse(url),
            headers: const {'Accept': 'application/pdf'},
          )
          .timeout(const Duration(seconds: 45));

      leadwayLog('<-- ${response.statusCode} $url');
      leadwayLog('[Leadway] PDF $label — taille: ${response.bodyBytes.length} octets');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.bodyBytes.isEmpty) {
          throw const LeadwayApiException(message: 'Le fichier PDF reçu est vide.');
        }
        return response.bodyBytes;
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
      throw LeadwayApiException.fromResponse(response.statusCode, decoded);
    } catch (e) {
      if (e is LeadwayApiException) rethrow;
      if (isLeadwayNetworkError(e)) {
        if (!kDebugMode) throw LeadwayApiException.unreachable;
        leadwayLog('[LeadwayApiService] PDF download failed: $e. Falling back to simulation...');
        return _simulateDownloadPdf(url, label, policyNo);
      }
      rethrow;
    }
  }

  Uint8List _simulateDownloadPdf(String url, String label, String policyNo) {
    leadwayLog('--> GET $url (MODE SIMULATION DÉMO PDF $label)');
    final content = '''
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 400 200]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length 120>>stream
BT /F1 14 Tf 40 150 Td (Leadway Assurance - $label) Tj 0 -24 Td (Police: $policyNo) Tj 0 -24 Td (Document de demonstration) Tj ET
endstream
endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000266 00000 n 
0000000438 00000 n 
trailer<</Size 6/Root 1 0 R>>
startxref
515
%%EOF''';
    leadwayLog('[Leadway] PDF $label — réponse simulée (${content.length} octets)');
    return Uint8List.fromList(utf8.encode(content));
  }

  // ==========================================
  // Méthodes de simulation réalistes
  // ==========================================

  Future<LeadwayPremiumResult> _simulateCalculatePremium(String url, LeadwayPremiumRequest request) async {
    leadwayLog('--> POST $url (MODE SIMULATION DÉMO)');
    leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
    leadwayLog('Request Body: ${jsonEncode(request.toJson())}');

    // Attente réaliste pour mimer le réseau
    await Future.delayed(const Duration(milliseconds: 1200));

    final vehicule = request.cotation.vehicule;
    final category = vehicule.categorieVehicule;
    final isMoto = category == LeadwayVehicleCategory.moto || category == LeadwayVehicleCategory.motoLight;

    int baseRC;
    int defenseRecours;
    int securite;
    int assistance;
    int vol;
    int incendie;
    int brisGlace;
    int recoursAnticipe;

    if (isMoto) {
      final cylinderVal = vehicule.cylindree;
      // Calcul de prime conforme au barème moto
      baseRC = (cylinderVal <= 125) ? 18600 : 28400;
      defenseRecours = 3000;
      securite = vehicule.garantieSecuriteRoutiere ? 3000 : 0;
      assistance = vehicule.garantieAssistanceAuto * 1000;
      vol = vehicule.garantieVol ? 5000 : 0;
      incendie = vehicule.garantieIncendie ? 4000 : 0;
      brisGlace = vehicule.garantieBrisDeGlace ? 2500 : 0;
      recoursAnticipe = vehicule.garantieRecoursAnticipe ? 1500 : 0;
    } else {
      // Calcul de prime conforme au barème auto
      final puissance = vehicule.puissanceFiscale;
      baseRC = 35000 + (puissance * 8000);
      final product = vehicule.codeProduit;

      if (product == LeadwayProductCode.tiersSimple) {
        defenseRecours = 0;
        securite = 0;
        assistance = 0;
        vol = 0;
        incendie = 0;
        brisGlace = 0;
        recoursAnticipe = 0;
      } else if (product == LeadwayProductCode.tiersComplet) {
        defenseRecours = 5000;
        securite = 0;
        assistance = 0;
        vol = 0;
        incendie = 0;
        brisGlace = 0;
        recoursAnticipe = 0;
      } else if (product == LeadwayProductCode.tousRisques) {
        defenseRecours = 5000;
        securite = 5000;
        assistance = vehicule.garantieAssistanceAuto * 5000;
        vol = (vehicule.valeurVenale * 0.015).round();
        incendie = (vehicule.valeurVenale * 0.01).round();
        brisGlace = 10000;
        recoursAnticipe = 5000;
      } else {
        // Sur Mesure (Garanties au choix)
        defenseRecours = 5000;
        securite = vehicule.garantieSecuriteRoutiere ? 5000 : 0;
        assistance = vehicule.garantieAssistanceAuto * 5000;
        vol = vehicule.garantieVol ? 15000 : 0;
        incendie = vehicule.garantieIncendie ? 10000 : 0;
        brisGlace = vehicule.garantieBrisDeGlace ? 8000 : 0;
        recoursAnticipe = vehicule.garantieRecoursAnticipe ? 4000 : 0;
      }
    }

    int primeNette = baseRC + defenseRecours + securite + assistance + vol + incendie + brisGlace + recoursAnticipe;
    int taxes = (primeNette * 0.145).round();
    int accessoires = 3000;
    int cedeao = 1000;
    int fga = (primeNette * 0.02).round();
    int primeTTC = primeNette + taxes + accessoires + cedeao + fga;
    final frais = (primeTTC * 0.03).toStringAsFixed(2);

    final mockJson = {
      "result": [
        {
          "element": {
            "code": "N/A",
            "type": "N/A",
            "attributeCode": "N/A",
            "profileCode": "N/A",
          },
          "resultValue": {
            "detailsPrime": {
              "primeNette": primeNette,
              "taxes": taxes,
              "accessoires": accessoires,
              "cedeao": cedeao,
              "fga": fga,
              "primeTTC": primeTTC,
              "frais": double.parse(frais),
            },
            "listeGaranties": {
              "garantieRC": baseRC,
              "garantieDefenseRecours": defenseRecours,
              "garantieBrisDeGlace": brisGlace,
              "garantieIncendie": incendie,
              "garantieVol": vol,
              "garantieVolAccessoires": 0,
              "garantieDommageCollision": 0,
              "garantieDommagesTousAccidents": 0,
              "garantieRecoursAnticipe": recoursAnticipe,
              "garantieAssistanceAuto": assistance,
              "garantieVie": 1000,
              "garantieSecuriteRoutiere": securite,
            },
          },
        },
      ],
    };

    final mockResponseJsonStr = jsonEncode(mockJson);
    leadwayLog('<-- 200 $url (SIMULATION DÉMO RESPONSE)');
    leadwayLog('Response Body: $mockResponseJsonStr');

    return LeadwayPremiumResult.fromJson(mockJson);
  }

  Future<LeadwayQuoteResponse> _simulateCreateQuote(String url, LeadwayQuoteRequest request) async {
    leadwayLog('--> POST $url (MODE SIMULATION DÉMO)');
    leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
    leadwayLog('Request Body: ${jsonEncode(request.toJson())}');

    await Future.delayed(const Duration(milliseconds: 1000));

    final cleanName = request.fullName.replaceAll(RegExp(r'\s+'), '_').toUpperCase();
    final isMoto = request.businessType == 'motor' || request.quoteType == 'motor';
    final prefix = isMoto ? 'MOTO' : 'AUTO';
    final quoteNo = 'QT-$prefix-${DateTime.now().year}-${10000 + (request.fullName.hashCode % 90000).abs()}';
    final id = 'devis_${cleanName}_${(request.phoneNo.hashCode).abs().toRadixString(16)}';
    
    final mockJson = {
      "quoteNo": quoteNo,
      "id": id,
      "quoteAmount": request.quoteAmount,
    };

    final mockResponseJsonStr = jsonEncode(mockJson);
    leadwayLog('<-- 200 $url (SIMULATION DÉMO RESPONSE)');
    leadwayLog('Response Body: $mockResponseJsonStr');

    return LeadwayQuoteResponse.fromJson(mockJson);
  }

  Future<Map<String, dynamic>> _simulateInitPayment(String url, LeadwayApiPaymentInitRequest request) async {
    leadwayLog('--> POST $url (MODE SIMULATION DÉMO)');
    leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
    leadwayLog('Request Body: ${jsonEncode(request.toJson())}');

    await Future.delayed(const Duration(milliseconds: 800));

    final paymentId = 'pay-${DateTime.now().millisecondsSinceEpoch}';
    final mockJson = {
      'paymentId': paymentId,
      'token': 'sim-token-$paymentId',
      'status': 'INITIATED',
      'message': 'Paiement ${request.operator} initié pour le devis ${request.quoteNo}.',
    };

    leadwayLog('<-- 200 $url (SIMULATION DÉMO RESPONSE)');
    leadwayLog('[Leadway] Init paiement — réponse (200): ${jsonEncode(mockJson)}');

    return mockJson;
  }

  Future<Map<String, dynamic>> _simulateConfirmPayment(String url, LeadwayApiPaymentRequest request) async {
    leadwayLog('--> POST $url (MODE SIMULATION DÉMO)');
    leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
    leadwayLog('Request Body: ${jsonEncode(request.toJson())}');

    await Future.delayed(const Duration(milliseconds: 800));

    final mockJson = {
      'status': 'PENDING',
      'paymentId': request.paymentId,
      'message': request.operator == LeadwayPaymentOperator.peyapay
          ? 'Paiement Peya Pay en cours de validation.'
          : 'Demande de paiement ${request.operator} envoyée sur le numéro ${request.phoneNo}.',
      'paid': false,
    };

    leadwayLog('<-- 200 $url (SIMULATION DÉMO RESPONSE)');
    leadwayLog('Response Body: ${jsonEncode(mockJson)}');

    return mockJson;
  }

  Future<Map<String, dynamic>> _simulateCheckPaymentStatus(String url, LeadwayApiPaymentCheckRequest request) async {
    leadwayLog('--> POST $url (MODE SIMULATION DÉMO)');
    leadwayLog('Headers: {Content-Type: application/json, Accept: application/json}');
    leadwayLog('Request Body: ${jsonEncode(request.toJson())}');

    await Future.delayed(const Duration(milliseconds: 1000));

    final attempts = _checkAttempts[request.paymentId] ?? 0;
    _checkAttempts[request.paymentId] = attempts + 1;

    Map<String, dynamic> mockJson;
    if (attempts == 0) {
      mockJson = {
        "status": "PENDING",
        "paid": false,
        "message": "Validation en attente. Veuillez accepter l'invite USSD reçue sur votre téléphone ou composer le code de validation."
      };
    } else {
      mockJson = {
        'status': 'PAID',
        'policyNo': '02070-${DateTime.now().millisecondsSinceEpoch}',
        'paid': true,
        'message': 'Paiement validé avec succès !',
      };
    }

    final mockResponseJsonStr = jsonEncode(mockJson);
    leadwayLog('<-- 200 $url (SIMULATION DÉMO RESPONSE)');
    leadwayLog('Response Body: $mockResponseJsonStr');

    return mockJson;
  }
}
