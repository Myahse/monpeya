class BilletterieEnvRegistry {
  BilletterieEnvRegistry._();

  /// Shared / legacy ticketing host (`BILLETTERIE_API_URL`).
  static String? baseUrl;

  /// Optional dedicated transport host (`BILLETTERIE_TRANSPORT_API_URL`).
  static String? transportBaseUrl;

  /// Optional dedicated event host (`BILLETTERIE_EVENT_API_URL`).
  static String? eventBaseUrl;

  static String? qrEncryptKey;

  static void apply({
    String? baseUrl,
    String? transportBaseUrl,
    String? eventBaseUrl,
    String? qrEncryptKey,
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
    if (qrEncryptKey != null && qrEncryptKey.isNotEmpty) {
      BilletterieEnvRegistry.qrEncryptKey = qrEncryptKey;
    }
  }

  static void reset() {
    baseUrl = null;
    transportBaseUrl = null;
    eventBaseUrl = null;
    qrEncryptKey = null;
  }
}
