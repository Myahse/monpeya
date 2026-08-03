/// App configuration — single source of truth (no `.env`).
///
/// Emulator: `10.0.2.2` = host localhost.
/// Physical device / LAN: use your PC IP, e.g. `http://192.168.28.236:8081`.
abstract final class AppConfig {
  // ── Local backends ────────────────────────────────────────────────────────
  static const monPeyaApiUrl = 'http://10.0.2.2:8081';
  static const immoApiUrl = 'http://10.0.2.2:8082';
  static const billetterieApiUrl = 'http://10.0.2.2:8090';
  static const immoWsUrl = 'ws://10.0.2.2:8082/ws/realtime';
  static const billetterieTransportApiUrl = '';
  static const billetterieEventApiUrl = '';
  static const billetterieWsUrl = 'ws://10.0.2.2:8090/ws';

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

  // ── Optional ──────────────────────────────────────────────────────────────
  static const mapboxAccessToken =
      'pk.eyJ1IjoibXlhaHNlIiwiYSI6ImNtcnYxNWkxejBqYmIyd3F3N2x0ZnVkcWUifQ.NhQAmCqR97BgPCs8G3fVFA';

  // ── Debug (debug builds only) ─────────────────────────────────────────────
  static const forceGuestMode = false;
  static const skipForcedAuth = false;
}
