import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:peyapay/src/core/constants/peyapay_api.constants.dart';
import 'package:peyapay/src/data/models/peyapay_api.exception.dart';

/// Encrypts / decrypts field values via Djogana NCG crypto API.
class PeyapayCryptoService {
  PeyapayCryptoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// True when [value] looks like an NCG/base64 cipher (not a plain phone or PIN).
  static bool looksLikeEncrypted(String value) {
    final text = value.trim();
    if (text.isEmpty) return false;
    if (text.startsWith('DPAY')) return false;
    if (RegExp(r'^\d{1,12}$').hasMatch(text)) return false;
    if (text.length < 16) return false;
    return RegExp(r'^[A-Za-z0-9+/]+=*$').hasMatch(text);
  }

  static String maskCipher(String cipher) {
    if (cipher.isEmpty) return '(empty)';
    final head = cipher.length <= 12 ? cipher : '${cipher.substring(0, 12)}…';
    return '$head (${cipher.length} chars)';
  }

  /// Encrypts [plainText] for PeyaPay API fields; reuses values already encrypted.
  Future<String> encryptForApi(String plainText, {required String label}) async {
    final value = plainText.trim();
    if (value.isEmpty) {
      throw PeyapayApiException(message: '$label vide');
    }

    if (looksLikeEncrypted(value)) {
      if (kDebugMode) {
        debugPrint('[PinAuth] $label déjà chiffré: ${maskCipher(value)}');
      }
      return value;
    }

    if (kDebugMode) {
      debugPrint('[PinAuth] Chiffrement NCG $label via ${PeyapayApiConfig.cryptoBaseUrl}/crypt');
    }

    final encrypted = await encryptString(value);
    if (encrypted == null || encrypted.isEmpty) {
      throw PeyapayApiException(
        message: 'Impossible de chiffrer $label (crypto API sans réponse)',
      );
    }
    if (!looksLikeEncrypted(encrypted)) {
      throw PeyapayApiException(
        message:
            '$label non chiffré après appel crypto — vérifiez PEYAPAY_CRYPTO_URL (${PeyapayApiConfig.cryptoBaseUrl})',
      );
    }

    if (kDebugMode) {
      debugPrint('[PinAuth] OK $label chiffré: ${maskCipher(encrypted)}');
    }
    return encrypted;
  }

  Future<String?> encryptString(String plainText) async {
    final value = plainText.trim();
    if (value.isEmpty) return null;

    final uri = Uri.parse('${PeyapayApiConfig.cryptoBaseUrl}/crypt');
    final response = await _client
        .post(
          uri,
          headers: _jsonHeaders,
          body: jsonEncode({
            'data': {'string': value},
          }),
        )
        .timeout(PeyapayApiConfig.apiTimeout);

    return _extractStringField(response, operation: 'chiffrement');
  }

  Future<String?> decryptString(String encryptedText) async {
    final value = encryptedText.trim();
    if (value.isEmpty) return null;
    if (!looksLikeEncrypted(value)) return value;

    final uri = Uri.parse('${PeyapayApiConfig.cryptoBaseUrl}/decrypt');
    final response = await _client
        .post(
          uri,
          headers: _jsonHeaders,
          body: jsonEncode({
            'data': {'string': value},
          }),
        )
        .timeout(PeyapayApiConfig.apiTimeout);

    return _extractStringField(response, operation: 'déchiffrement');
  }

  String? _extractStringField(http.Response response, {required String operation}) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PeyapayApiException(
        message: 'Échec du $operation (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw PeyapayApiException(message: 'Réponse $operation invalide');
    }

    if (decoded['hasError'] == true) {
      throw PeyapayApiException.fromResponse(response.statusCode, decoded);
    }

    final item = decoded['item'];
    if (item is Map && item['string'] != null) {
      return item['string'].toString();
    }
    final data = decoded['data'];
    if (data is Map && data['string'] != null) {
      return data['string'].toString();
    }
    if (decoded['string'] != null) {
      return decoded['string'].toString();
    }
    return null;
  }

}

  /// Normalizes CI mobile numbers to 10 local digits.
String normalizePeyapayPhone(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00225') && digits.length > 10) {
    digits = digits.substring(5);
  } else if (digits.startsWith('225') && digits.length > 10) {
    digits = digits.substring(3);
  }
  return digits;
}
