import 'package:billetterie/billetterie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:immo/immo.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/api/mon_peya_api.config.dart';

/// Loads `app/.env` and applies values to module env registries.
///
/// All sensitive PeyaPay credentials live in `.env` (marchand_dart parity).
abstract final class MonPeyaEnv {
  static bool _loaded = false;

  /// When true (debug only), [AuthStore] behaves as if no account exists on device.
  static bool forceGuestMode = false;

  /// When true (debug only), [ModuleAuth.ensureRegistered] and session unlock skip login.
  static bool skipForcedAuth = false;

  static Future<void> load() async {
    if (_loaded) return;

    final loaded = await _loadDotEnv();
    if (!loaded && kDebugMode) {
      debugPrint('MonPeyaEnv: missing app/.env — copy app/.env.example to app/.env');
    }

    _applyToModules();
    _applyDebugAuthFlags();
    if (kDebugMode) {
      debugPrint('MonPeyaEnv: MONPEYA_API_URL → ${MonPeyaApiConfig.baseUrl}');
      if (forceGuestMode || skipForcedAuth) {
        debugPrint(
          'MonPeyaEnv: debug auth — FORCE_GUEST_MODE=$forceGuestMode, '
          'SKIP_FORCED_AUTH=$skipForcedAuth',
        );
      }
      final qrKey = PeyapayEnvRegistry.qrEncryptKey ?? PeyapayEnvRegistry.encryptKey;
      if (qrKey == null || qrKey.length < 32) {
        debugPrint(
          'MonPeyaEnv: QR key missing or too short (${qrKey?.length ?? 0} chars). '
          'Quote ENCRYPT_KEY in .env if it contains #.',
        );
      }
    }
    _loaded = true;
  }

  static Future<bool> _loadDotEnv() async {
    try {
      await dotenv.load(fileName: '.env');
      return true;
    } catch (_) {
      if (!kDebugMode) return false;
      try {
        await dotenv.load(fileName: '.env.example');
        debugPrint('MonPeyaEnv: using .env.example — copy to .env for secrets');
        return true;
      } catch (_) {}
    }
    return false;
  }

  static void _applyToModules() {
    final encryptKey = _first([
      'ENCRYPT_KEY',
      'PEYAPAY_ENCRYPT_KEY',
    ]);
    final qrEncryptKey = _first([
      'QR_ENCRYPT_KEY',
      'PEYAPAY_QR_ENCRYPT_KEY',
    ]);

    MonPeyaApiConfig.apply(
      baseUrl: _first(['MONPEYA_API_URL', 'API_BASE_URL']),
    );

    PeyapayEnvRegistry.apply(
      apiUrl: _optional('PEYAPAY_API_URL'),
      cryptoUrl: _optional('PEYAPAY_CRYPTO_URL'),
      useProd: _boolOptional('PEYAPAY_USE_PROD'),
      appUsername: _first(['PEYAPAY_APP_USERNAME', 'APP_ADMIN_USERNAME']),
      appPassword: _first(['PEYAPAY_APP_PASSWORD', 'APP_ADMIN_PASSWORD']),
      appToken: _first(['APP_TOKEN', 'PEYAPAY_APP_TOKEN']),
      encryptKey: encryptKey,
      qrEncryptKey: qrEncryptKey ?? encryptKey,
      tokenEndpoint: _first(['TOKEN_ENDPOINT', 'PEYAPAY_TOKEN_ENDPOINT']),
    );

    ImmoEnvRegistry.apply(
      baseUrl: _first(['IMMO_API_URL', 'RENTAL_API_URL']),
    );

    BilletterieEnvRegistry.apply(
      baseUrl: _optional('BILLETTERIE_API_URL'),
      transportBaseUrl: _optional('BILLETTERIE_TRANSPORT_API_URL'),
      eventBaseUrl: _optional('BILLETTERIE_EVENT_API_URL'),
      qrEncryptKey: qrEncryptKey ?? encryptKey,
    );
  }

  static void _applyDebugAuthFlags() {
    forceGuestMode = _boolOptional('FORCE_GUEST_MODE') ?? false;
    skipForcedAuth = _boolOptional('SKIP_FORCED_AUTH') ?? false;
  }

  static String? _first(List<String> keys) {
    for (final key in keys) {
      final value = _optional(key);
      if (value != null) return value;
    }
    return null;
  }

  static String? _optional(String key) {
    final raw = dotenv.maybeGet(key);
    if (raw == null) return null;

    var value = raw.trim();
    if (value.isEmpty) return null;

    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1).trim();
    }

    return value.isEmpty ? null : value;
  }

  static bool? _boolOptional(String key) {
    final value = _optional(key);
    if (value == null) return null;
    return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
  }
}
