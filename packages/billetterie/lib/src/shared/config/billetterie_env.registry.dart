class BilletterieEnvRegistry {
  BilletterieEnvRegistry._();

  /// Shared / legacy ticketing host (`BILLETTERIE_API_URL`).
  static String? baseUrl;

  /// Optional dedicated transport host (`BILLETTERIE_TRANSPORT_API_URL`).
  static String? transportBaseUrl;

  /// Optional dedicated event host (`BILLETTERIE_EVENT_API_URL`).
  static String? eventBaseUrl;

  /// Optional WebSocket URL (`BILLETTERIE_WS_URL`).
  static String? wsUrl;

  static String? qrEncryptKey;

  /// Mapbox Directions / Maps token (`MAPBOX_ACCESS_TOKEN`).
  static String? mapboxAccessToken;

  static void apply({
    String? baseUrl,
    String? transportBaseUrl,
    String? eventBaseUrl,
    String? wsUrl,
    String? qrEncryptKey,
    String? mapboxAccessToken,
  }) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      BilletterieEnvRegistry.baseUrl = baseUrl;
    }
    if (transportBaseUrl != null && transportBaseUrl.isNotEmpty) {
      BilletterieEnvRegistry.transportBaseUrl = transportBaseUrl;
    }
    if (eventBaseUrl != null && eventBaseUrl.isNotEmpty) {
      BilletterieEnvRegistry.eventBaseUrl = eventBaseUrl;
    }
    if (wsUrl != null && wsUrl.isNotEmpty) {
      BilletterieEnvRegistry.wsUrl = wsUrl;
    }
    if (qrEncryptKey != null && qrEncryptKey.isNotEmpty) {
      BilletterieEnvRegistry.qrEncryptKey = qrEncryptKey;
    }
    if (mapboxAccessToken != null && mapboxAccessToken.isNotEmpty) {
      BilletterieEnvRegistry.mapboxAccessToken = mapboxAccessToken;
    }
  }

  static void reset() {
    baseUrl = null;
    transportBaseUrl = null;
    eventBaseUrl = null;
    wsUrl = null;
    qrEncryptKey = null;
    mapboxAccessToken = null;
  }
}
