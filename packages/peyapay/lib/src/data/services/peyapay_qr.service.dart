import 'dart:convert';

import 'package:peyapay/src/core/constants/peyapay_api.constants.dart';
import 'package:peyapay/src/core/constants/peyapay_qr.constants.dart';
import 'package:peyapay/src/data/models/peyapay_scanned_qr.model.dart';
import 'package:secure_qr_generator/secure_qr_generator.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

/// PeyaPay secure QR generation and validation (secure_qr_generator 1.1+).
class PeyapayQrService {
  PeyapayQrService({String? secretKey}) : _overrideKey = secretKey?.trim();

  final String? _overrideKey;

  String get _secretKey => (_overrideKey ?? PeyapayApiConfig.qrEncryptKey).trim();

  bool get hasSecretKey => _secretKey.length >= 32;

  GeneratorConfig get _walletGeneratorConfig => GeneratorConfig(
        secretKey: hasSecretKey ? _secretKey : null,
        validityDuration: const Duration(
          seconds: PeyapayQrConstants.generatorValiditySeconds,
        ),
        enableEncryption: false,
        enableSignature: hasSecretKey,
        payloadFormat: QrPayloadFormat.compact,
      );

  SecureQRGenerator get _walletGenerator => SecureQRGenerator(_walletGeneratorConfig);

  SecureQRGenerator get _ticketGenerator => SecureQRGenerator(
        GeneratorConfig(
          secretKey: hasSecretKey ? _secretKey : null,
          enableEncryption: hasSecretKey,
          enableSignature: hasSecretKey,
          validityDuration: const Duration(days: 365),
          dataVersion: 1,
          idPrefix: 'TKT-',
          payloadFormat: QrPayloadFormat.legacy,
        ),
      );

  SecureQRValidator get _walletValidator => SecureQRValidator(
        ValidatorConfig(
          secretKey: hasSecretKey ? _secretKey : null,
          validityDuration: const Duration(
            seconds: PeyapayQrConstants.generatorValiditySeconds,
          ),
          enableEncryption: false,
          enableSignature: hasSecretKey,
          enableExpirationCheck: false,
        ),
      );

  Future<GenerationResult> generateWalletQr({
    required String clientCodeKey,
    required String displayName,
    String? phone,
    String? traitementId,
    String userTypeKey = PeyapayQrUserTypes.client,
  }) {
    final phoneDigits = (phone ?? clientCodeKey).trim();

    final payload = <String, dynamic>{
      PeyapayQrKeys.clientCode: clientCodeKey,
      PeyapayQrKeys.phone: phoneDigits,
      PeyapayQrKeys.userNames: displayName,
      PeyapayQrKeys.userType: userTypeKey,
      if (traitementId != null && traitementId.isNotEmpty)
        PeyapayQrKeys.traitementId: traitementId,
    };

    return _walletGenerator.generateQR(QRData(payload: payload));
  }

  /// Ticketing QR — long-lived legacy encrypted payload validated by the ticketing backend.
  Future<GenerationResult> generateTicketQr({
    required String ticketCode,
    String? eventCode,
    required String purpose,
    required String title,
  }) {
    return _ticketGenerator.generateQR(
      QRData(
        payload: {
          'ticketCodeKey': ticketCode,
          'eventCodeKey': eventCode ?? '',
          'purposeKey': purpose,
          'titleKey': title,
          'userTypeKey': 'TKT',
        },
      ),
    );
  }

  PeyapayScannedQrData? parseScannedCode(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;

    final validation = _walletValidator.validateQRPayload(trimmed);
    final extracted = _extractFromValidation(validation);
    if (extracted != null) return extracted;

    return _extractFromLegacyFormats(trimmed);
  }

  PeyapayScannedQrData? _extractFromValidation(ValidationResult validation) {
    final qrData = validation.data;
    if (qrData == null) return null;

    final payload = qrData['payload'];
    if (payload is Map<String, dynamic>) {
      return _buildScannedData(
        payload: payload,
        isExpired: validation.isExpired,
      );
    }

    return _buildScannedData(
      payload: qrData,
      isExpired: validation.isExpired,
    );
  }

  PeyapayScannedQrData? _extractFromLegacyFormats(String scannedCode) {
    try {
      final jsonData = jsonDecode(scannedCode);
      if (jsonData is Map<String, dynamic>) {
        if (jsonData['payload'] is Map<String, dynamic>) {
          return _buildScannedData(payload: jsonData['payload'] as Map<String, dynamic>);
        }
        return _buildScannedData(payload: jsonData);
      }
    } catch (_) {}

    try {
      final decodedString = utf8.decode(base64Decode(scannedCode));
      final jsonData = jsonDecode(decodedString);
      if (jsonData is Map<String, dynamic>) {
        final data = jsonData['data'];
        if (data is Map<String, dynamic>) {
          final payload = data['payload'];
          if (payload is Map<String, dynamic>) {
            return _buildScannedData(payload: payload);
          }
        }
      }
    } catch (_) {}

    return null;
  }

  PeyapayScannedQrData? _buildScannedData({
    required Map<String, dynamic> payload,
    bool isExpired = false,
  }) {
    final clientCodeKey = _readPayloadString(payload, [
      PeyapayQrKeys.phone,
      PeyapayQrKeys.clientCode,
      'clientCodeKey',
      'valeurQr',
      'codeClient',
    ]);

    if (clientCodeKey == null || clientCodeKey.isEmpty) return null;

    return PeyapayScannedQrData(
      clientCodeKey: clientCodeKey,
      displayName: _readPayloadString(payload, [
        PeyapayQrKeys.userNames,
        'usernamesKey',
      ]),
      userTypeKey: _readPayloadString(payload, [
        PeyapayQrKeys.userType,
        'userTypeKey',
        'typeUser',
      ]),
      isExpired: isExpired,
    );
  }

  String? _readPayloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

abstract final class PeyapayQrUserTypes {
  static const merchant = 'MPP';
  static const client = 'CPP';
}
