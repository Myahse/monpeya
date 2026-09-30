/// Runtime config injected by Mon Peya at startup ([MonPeyaEnv.load]).
class SimEnvRegistry {
  SimEnvRegistry._();

  static String? apiKey;
  static String? baseUrl;
  static String? webhookSecret;

  static void apply({
    String? apiKey,
    String? baseUrl,
    String? webhookSecret,
  }) {
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      SimEnvRegistry.apiKey = apiKey.trim();
    }
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      SimEnvRegistry.baseUrl = baseUrl.trim();
    }
    if (webhookSecret != null && webhookSecret.trim().isNotEmpty) {
      SimEnvRegistry.webhookSecret = webhookSecret.trim();
    }
  }
}
