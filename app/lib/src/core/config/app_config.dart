/// App configuration — every value comes from `--dart-define`.
///
/// Nothing secret lives in source control. Copy `config/env.example.json`
/// to `config/env.json` (git-ignored), fill it in, then run from `app/`:
///
/// `flutter run --dart-define-from-file=config/env.json`
///
/// Defaults below are safe placeholders for the Android emulator
/// (`10.0.2.2` = host machine). On a physical phone, put the PC's LAN IP in
/// `env.json` (see `tool/sync_dev_lan_host.ps1`).
///
/// Note: any value compiled into the app can be extracted from the binary.
/// Partner keys (`SIM_API_KEY`) and PeyaPay admin credentials should move
/// behind the Mon Peya backend; the defines are a stop-gap for dev builds.
abstract final class AppConfig {
  // ── Local backends ────────────────────────────────────────────────────────
  static const monPeyaApiUrl = String.fromEnvironment(
    'MONPEYA_API_URL',
    defaultValue: 'http://10.0.2.2:8081',
  );
  static const immoApiUrl = String.fromEnvironment(
    'IMMO_API_URL',
    defaultValue: 'http://10.0.2.2:8082',
  );
  static const billetterieApiUrl = String.fromEnvironment(
    'BILLETTERIE_API_URL',
    defaultValue: 'http://10.0.2.2:8090',
  );
  static const immoWsUrl = String.fromEnvironment(
    'IMMO_WS_URL',
    defaultValue: 'ws://10.0.2.2:8082/ws/realtime',
  );
  static const billetterieTransportApiUrl =
      String.fromEnvironment('BILLETTERIE_TRANSPORT_API_URL');
  static const billetterieEventApiUrl =
      String.fromEnvironment('BILLETTERIE_EVENT_API_URL');
  static const billetterieWsUrl = String.fromEnvironment(
    'BILLETTERIE_WS_URL',
    defaultValue: 'ws://10.0.2.2:8090/ws',
  );
  static const grenierApiUrl = String.fromEnvironment(
    'GRENIER_API_URL',
    defaultValue: 'http://10.0.2.2:8083',
  );
  static const grenierWsUrl = String.fromEnvironment(
    'GRENIER_WS_URL',
    defaultValue: 'ws://10.0.2.2:8083/ws/realtime',
  );

  // ── SIM Assurances ─────────────────────────────────────────────────────────
  static const simApiBaseUrl = String.fromEnvironment(
    'SIM_API_URL',
    defaultValue: 'https://protect.mysimassurances.com/api/partner/v1',
  );
  /// Partner API key from SIM Assurances (`sk_...`).
  static const simApiKey = String.fromEnvironment('SIM_API_KEY');
  static const simWebhookSecret = String.fromEnvironment('SIM_WEBHOOK_SECRET');

  // ── PeyaPay ───────────────────────────────────────────────────────────────
  static const peyaPayApiUrl = String.fromEnvironment(
    'PEYAPAY_API_URL',
    defaultValue: 'https://test1-pey-peya.djogana-pay.com',
  );
  static const peyaPayCryptoUrl = String.fromEnvironment(
    'PEYAPAY_CRYPTO_URL',
    defaultValue: 'https://djoganapayci.com/api10/peya-2.0/ncg',
  );
  static const peyaPayUseProd = bool.fromEnvironment('PEYAPAY_USE_PROD');
  static const tokenEndpoint = String.fromEnvironment(
    'PEYAPAY_TOKEN_ENDPOINT',
    defaultValue: '/authclient/token',
  );
  static const encryptKey = String.fromEnvironment('ENCRYPT_KEY');
  static const qrEncryptKey = String.fromEnvironment('QR_ENCRYPT_KEY');
  static const appToken = String.fromEnvironment('PEYAPAY_APP_TOKEN');
  static const appAdminUsername =
      String.fromEnvironment('PEYAPAY_APP_USERNAME');
  static const appAdminPassword =
      String.fromEnvironment('PEYAPAY_APP_PASSWORD');

  static const mapboxAccessToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  // ── Debug (debug builds only) ─────────────────────────────────────────────
  static const forceGuestMode = bool.fromEnvironment('FORCE_GUEST_MODE');
  static const skipForcedAuth = bool.fromEnvironment('SKIP_FORCED_AUTH');
}
