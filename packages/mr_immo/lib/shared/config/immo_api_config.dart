/// API configuration shared across Mr Immo Flutter modules.
abstract final class ImmoApiConfig {
  /// Spring Boot API — `--dart-define=IMMO_API_URL=http://192.168.x.x:8081`
  static const baseUrl = String.fromEnvironment(
    'IMMO_API_URL',
    defaultValue: String.fromEnvironment(
      'RENTAL_API_URL',
      defaultValue: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8081',
      ),
    ),
  );

  static const timeoutMs = 15000;
}
