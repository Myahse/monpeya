class GrenierEnvRegistry {
  GrenierEnvRegistry._();

  static String? baseUrl;
  static String? wsUrl;

  static void apply({String? baseUrl, String? wsUrl}) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      GrenierEnvRegistry.baseUrl = baseUrl;
    }
    if (wsUrl != null && wsUrl.isNotEmpty) {
      GrenierEnvRegistry.wsUrl = wsUrl;
    }
  }
}
