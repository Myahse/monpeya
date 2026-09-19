import 'package:billetterie/billetterie.dart';
import 'package:flutter/foundation.dart';
import 'package:grenier/grenier.dart';
import 'package:immo/immo.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/api/mon_peya_api.config.dart';
import 'package:app/src/core/config/app_config.dart';

/// Applies [AppConfig] to all modules. No `.env` loading.
abstract final class MonPeyaEnv {
  static bool _loaded = false;

  static bool forceGuestMode = false;
  static bool skipForcedAuth = false;

  static Future<void> load() async {
    if (_loaded) return;

    _applyToModules();
    forceGuestMode = AppConfig.forceGuestMode;
    skipForcedAuth = AppConfig.skipForcedAuth;

    if (kDebugMode) {
      debugPrint('MonPeyaEnv: MONPEYA_API_URL → ${MonPeyaApiConfig.baseUrl}');
      debugPrint('MonPeyaEnv: IMMO_API_URL → ${ImmoApiConfig.baseUrl}');
      debugPrint('MonPeyaEnv: IMMO_WS_URL → ${ImmoApiConfig.wsUrl}');
      if (forceGuestMode || skipForcedAuth) {
        debugPrint(
          'MonPeyaEnv: debug auth — FORCE_GUEST_MODE=$forceGuestMode, '
          'SKIP_FORCED_AUTH=$skipForcedAuth',
        );
      }
      final qrKey =
          PeyapayEnvRegistry.qrEncryptKey ?? PeyapayEnvRegistry.encryptKey;
      if (qrKey == null || qrKey.length < 32) {
        debugPrint(
          'MonPeyaEnv: QR key missing or too short (${qrKey?.length ?? 0} chars). '
          'Set encryptKey / qrEncryptKey in AppConfig.',
        );
      }
      if (BilletterieEnvRegistry.mapboxAccessToken == null ||
          BilletterieEnvRegistry.mapboxAccessToken!.isEmpty) {
        debugPrint(
          'MonPeyaEnv: mapboxAccessToken missing — transport map '
          'falls back to straight-line routes.',
        );
      }
    }
    _loaded = true;
  }

  static void _applyToModules() {
    final encryptKey = _nonEmpty(AppConfig.encryptKey);
    final qrEncryptKey =
        _nonEmpty(AppConfig.qrEncryptKey) ?? encryptKey;

    MonPeyaApiConfig.apply(baseUrl: _nonEmpty(AppConfig.monPeyaApiUrl));

    PeyapayEnvRegistry.apply(
      apiUrl: _nonEmpty(AppConfig.peyaPayApiUrl),
      cryptoUrl: _nonEmpty(AppConfig.peyaPayCryptoUrl),
      useProd: AppConfig.peyaPayUseProd,
      appUsername: _nonEmpty(AppConfig.appAdminUsername),
      appPassword: _nonEmpty(AppConfig.appAdminPassword),
      appToken: _nonEmpty(AppConfig.appToken),
      encryptKey: encryptKey,
      qrEncryptKey: qrEncryptKey,
      tokenEndpoint: _nonEmpty(AppConfig.tokenEndpoint),
    );

    ImmoEnvRegistry.apply(
      baseUrl: _nonEmpty(AppConfig.immoApiUrl),
      wsUrl: _nonEmpty(AppConfig.immoWsUrl),
    );

    BilletterieEnvRegistry.apply(
      baseUrl: _nonEmpty(AppConfig.billetterieApiUrl),
      transportBaseUrl: _nonEmpty(AppConfig.billetterieTransportApiUrl),
      eventBaseUrl: _nonEmpty(AppConfig.billetterieEventApiUrl),
      wsUrl: _nonEmpty(AppConfig.billetterieWsUrl),
      qrEncryptKey: qrEncryptKey,
      mapboxAccessToken: _nonEmpty(AppConfig.mapboxAccessToken),
    );

    GrenierEnvRegistry.apply(
      baseUrl: _nonEmpty(AppConfig.grenierApiUrl),
      wsUrl: _nonEmpty(AppConfig.grenierWsUrl),
    );
  }

  static String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
