/// Runtime + compile-time config for the Monpeya backend (`/v1/*`).
abstract final class MonPeyaApiConfig {
  static const apiTimeout = Duration(seconds: 25);

  static const _defineBaseUrl = String.fromEnvironment(
    'MONPEYA_API_URL',
    defaultValue: 'http://10.0.2.2:8082/api/platform',
  );

  static String? _runtimeBaseUrl;

  static void apply({String? baseUrl}) {
    _runtimeBaseUrl = baseUrl?.trim();
  }

  static String get baseUrl {
    final runtime = _runtimeBaseUrl;
    if (runtime != null && runtime.isNotEmpty) return _stripTrailingSlash(runtime);
    return _stripTrailingSlash(_defineBaseUrl);
  }

  static String _stripTrailingSlash(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
