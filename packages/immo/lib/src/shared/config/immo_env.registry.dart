class ImmoEnvRegistry {
  ImmoEnvRegistry._();

  static String? baseUrl;


  static String? wsUrl;

  static void apply({String? baseUrl, String? wsUrl}) {
    if (baseUrl != null && baseUrl.isNotEmpty) ImmoEnvRegistry.baseUrl = baseUrl;
    if (wsUrl != null && wsUrl.isNotEmpty) ImmoEnvRegistry.wsUrl = wsUrl;
  }

  static void reset() {
    baseUrl = null;
    wsUrl = null;
  }
}
