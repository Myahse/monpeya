import 'dart:convert';

import 'package:sim/src/data/errors/sim_api.exception.dart';

/// Idempotency-Key must stay stable when retrying the same payload, and change when the body changes.
abstract final class SimIdempotency {
  static String fingerprintJson(Map<String, dynamic> body) {
    final encoded = jsonEncode(body);
    return '${encoded.length}:${encoded.hashCode}';
  }

  /// Reuse [currentKey] only when [currentFingerprint] matches [fingerprint]; otherwise [newKey].
  static String resolveKey({
    required String? currentKey,
    required String? currentFingerprint,
    required String fingerprint,
    required String newKey,
  }) {
    if (currentKey != null && currentFingerprint == fingerprint) {
      return currentKey;
    }
    return newKey;
  }

  static bool isBodyMismatch(SimApiException e) {
    final code = e.code?.toLowerCase() ?? '';
    final msg = e.message.toLowerCase();
    if (code.contains('idempotenc') && (code.contains('corps') || code.contains('body'))) {
      return true;
    }
    if (msg.contains('idempotenc') &&
        (msg.contains('corps') || msg.contains('body') || msg.contains('différent') || msg.contains('different'))) {
      return true;
    }
    return false;
  }
}
