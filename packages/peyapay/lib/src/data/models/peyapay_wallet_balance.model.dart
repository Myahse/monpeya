import 'package:flutter/foundation.dart';

import 'package:peyapay/src/data/services/peyapay_crypto.service.dart';

class PeyapayWalletBalance {
  const PeyapayWalletBalance({
    this.gsmPrincipale,
    this.codePaysResidence,
    this.soldeCipher,
    this.solde,
  });

  final String? gsmPrincipale;
  final String? codePaysResidence;
  final String? soldeCipher;
  final int? solde;

  static Future<PeyapayWalletBalance> fromApiJson(
    Map<String, dynamic> json, {
    required PeyapayCryptoService crypto,
  }) async {
    final soldeField = _readSoldeField(json);
    String? cipher;
    String? plain;

    if (soldeField is num) {
      plain = soldeField.toString();
    } else if (soldeField is String) {
      cipher = soldeField;
      if (PeyapayCryptoService.looksLikeEncrypted(soldeField)) {
        plain = await crypto.decryptString(soldeField);
        if ((plain == null || plain.trim().isEmpty) && kDebugMode) {
          debugPrint('[PinAuth] FAIL déchiffrement solde — cipher ${PeyapayCryptoService.maskCipher(soldeField)}');
        }
      } else {
        plain = soldeField;
      }
    } else if (kDebugMode && json.isNotEmpty) {
      debugPrint('[PinAuth] Solde absent dans la réponse — clés: ${json.keys.join(', ')}');
    }

    return PeyapayWalletBalance(
      gsmPrincipale: json['gsmPrincipale']?.toString(),
      codePaysResidence: json['codePaysResidence']?.toString(),
      soldeCipher: cipher,
      solde: _parseAmount(plain),
    );
  }

  static int? _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(RegExp(r'[^0-9.,-]'), '');
    if (normalized.isEmpty) return null;

    final asInt = int.tryParse(normalized.replaceAll(RegExp(r'[.,].*$'), ''));
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(normalized.replaceAll(',', '.'));
    if (asDouble != null) return asDouble.round();

    return null;
  }

  static Object? _readSoldeField(Map<String, dynamic> json) {
    for (final key in ['solde', 'montant', 'soldeDisponible', 'balance']) {
      final value = json[key];
      if (value != null) return value;
    }
    return null;
  }
}
