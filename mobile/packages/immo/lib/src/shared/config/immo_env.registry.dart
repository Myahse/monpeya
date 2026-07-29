class ImmoEnvRegistry {
  ImmoEnvRegistry._();

  static String? baseUrl;

  static void apply({String? baseUrl}) {
    if (baseUrl != null && baseUrl.isNotEmpty) ImmoEnvRegistry.baseUrl = baseUrl;
  }

  static void reset() => baseUrl = null;
}
