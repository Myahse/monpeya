/// App configuration — single source of truth (no `.env`).
///
/// **Physical phone / same Wi‑Fi:** PC LAN IP + port 8081 (see `ipconfig`).
/// **Android emulator:** `http://10.0.2.2:8081`
///
/// Override without editing code:
/// `flutter run --dart-define=MONPEYA_API_URL=http://10.0.2.2:8081`
abstract final class AppConfig {
  // ── Local backends ────────────────────────────────────────────────────────
  /// Default = PC on Wi‑Fi (`ipconfig` → IPv4). Change if your IP differs.
  static const monPeyaApiUrl = String.fromEnvironment(
    'MONPEYA_API_URL',
    defaultValue: 'http://192.168.28.236:8081',
  );
  static const immoApiUrl = 'http://10.0.2.2:8082';
  static const billetterieApiUrl = 'http://10.0.2.2:8090';
  static const immoWsUrl = 'ws://10.0.2.2:8082/ws/realtime';
  static const billetterieTransportApiUrl = '';
  static const billetterieEventApiUrl = '';
  static const billetterieWsUrl = 'ws://10.0.2.2:8090/ws';
  static const grenierApiUrl = 'http://10.0.2.2:8083';
  static const grenierWsUrl = 'ws://10.0.2.2:8083/ws/realtime';

  // ── SIM Assurances ─────────────────────────────────────────────────────────
  static const simApiBaseUrl =
      'https://protect.mysimassurances.com/api/partner/v1';
  /// Partner API key from SIM Assurances (sk_live_...). Set before running the app.
  static const simApiKey = 'sk_live_FlJDQklzvGEHedJPY2_1pXTHn0Z6Sxw74DUjQuzpBw0';
  static const simWebhookSecret = '';

  // ── PeyaPay ───────────────────────────────────────────────────────────────
  static const peyaPayApiUrl = 'https://test1-pey-peya.djogana-pay.com';
  static const peyaPayCryptoUrl = 'https://djoganapayci.com/api10/peya-2.0/ncg';
  static const peyaPayUseProd = false;
  static const tokenEndpoint = '/authclient/token';
  static const encryptKey = '2024#@#vdoss#djogan@##perform#==';
  static const qrEncryptKey = '2024#@#vdoss#djogan@##perform#==';
  static const appToken = '';
  static const appAdminUsername = '97m4r0Q4tD38WI5MHIay2Q==';
  static const appAdminPassword = 'wWFMgdAJEi+HT0h8olL11w==';

  static const mapboxAccessToken =
      'pk.eyJ1IjoibXlhaHNlIiwiYSI6ImNtcnYxNWkxejBqYmIyd3F3N2x0ZnVkcWUifQ.NhQAmCqR97BgPCs8G3fVFA';

  // ── Debug (debug builds only) ─────────────────────────────────────────────
  static const forceGuestMode = false;
  static const skipForcedAuth = false;
}
