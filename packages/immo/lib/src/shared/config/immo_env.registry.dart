class ImmoEnvRegistry {
  ImmoEnvRegistry._();

  static String? baseUrl;

  static String? wsUrl;

  /// Mapbox raster tiles + Directions (`MAPBOX_ACCESS_TOKEN` / AppConfig).
  static String? mapboxAccessToken;

  static void apply({
    String? baseUrl,
    String? wsUrl,
    String? mapboxAccessToken,
  }) {
    if (baseUrl != null && baseUrl.isNotEmpty) ImmoEnvRegistry.baseUrl = baseUrl;
    if (wsUrl != null && wsUrl.isNotEmpty) ImmoEnvRegistry.wsUrl = wsUrl;
    if (mapboxAccessToken != null && mapboxAccessToken.isNotEmpty) {
      ImmoEnvRegistry.mapboxAccessToken = mapboxAccessToken;
    }
  }

  static void reset() {
    baseUrl = null;
    wsUrl = null;
    mapboxAccessToken = null;
  }
}
