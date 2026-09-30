/// Runtime PeyaPay secrets and URLs (populated from `app/.env` at startup).
class PeyapayEnvRegistry {
  PeyapayEnvRegistry._();

  static String? apiUrl;
  static String? cryptoUrl;
  static bool? useProd;
  static String? appUsername;
  static String? appPassword;
  static String? appToken;
  static String? encryptKey;
  static String? qrEncryptKey;
  static String? tokenEndpoint;

  /// Mon Peya backend base URL (no trailing slash) — used for `/v1/carte/*`.
  static String? monPeyaApiUrl;

  static void apply({
    String? apiUrl,
    String? cryptoUrl,
    bool? useProd,
    String? appUsername,
    String? appPassword,
    String? appToken,
    String? encryptKey,
    String? qrEncryptKey,
    String? tokenEndpoint,
    String? monPeyaApiUrl,
  }) {
    if (apiUrl != null && apiUrl.isNotEmpty) PeyapayEnvRegistry.apiUrl = apiUrl;
    if (cryptoUrl != null && cryptoUrl.isNotEmpty) PeyapayEnvRegistry.cryptoUrl = cryptoUrl;
    if (useProd != null) PeyapayEnvRegistry.useProd = useProd;
    if (appUsername != null && appUsername.isNotEmpty) PeyapayEnvRegistry.appUsername = appUsername;
    if (appPassword != null && appPassword.isNotEmpty) PeyapayEnvRegistry.appPassword = appPassword;
    if (appToken != null && appToken.isNotEmpty) PeyapayEnvRegistry.appToken = appToken;
    if (encryptKey != null && encryptKey.isNotEmpty) PeyapayEnvRegistry.encryptKey = encryptKey;
    if (qrEncryptKey != null && qrEncryptKey.isNotEmpty) PeyapayEnvRegistry.qrEncryptKey = qrEncryptKey;
    if (tokenEndpoint != null && tokenEndpoint.isNotEmpty) {
      PeyapayEnvRegistry.tokenEndpoint = tokenEndpoint;
    }
    if (monPeyaApiUrl != null && monPeyaApiUrl.isNotEmpty) {
      PeyapayEnvRegistry.monPeyaApiUrl = monPeyaApiUrl;
    }
  }

  static void reset() {
    apiUrl = null;
    cryptoUrl = null;
    useProd = null;
    appUsername = null;
    appPassword = null;
    appToken = null;
    encryptKey = null;
    qrEncryptKey = null;
    tokenEndpoint = null;
    monPeyaApiUrl = null;
  }
}
