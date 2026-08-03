import 'package:immo/src/shared/config/immo_env.registry.dart';

/// API configuration shared across Mr Immo Flutter modules.
abstract final class ImmoApiConfig {
  static const _defineBaseUrl = String.fromEnvironment(
    'IMMO_API_URL',
    defaultValue: String.fromEnvironment(
      'RENTAL_API_URL',
      defaultValue: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8081',
      ),
    ),
  );

  static const _defineWsUrl = String.fromEnvironment(
    'IMMO_WS_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final runtime = ImmoEnvRegistry.baseUrl;
    if (runtime != null && runtime.isNotEmpty) {
      return _stripTrailingSlash(runtime);
    }
    return _stripTrailingSlash(_defineBaseUrl);
  }


  static String get wsUrl {
    final runtime = ImmoEnvRegistry.wsUrl;
    if (runtime != null && runtime.isNotEmpty) {
      return runtime.trim();
    }
    if (_defineWsUrl.trim().isNotEmpty) {
      return _defineWsUrl.trim();
    }
    return _wsFromHttp(baseUrl);
  }

  static const timeoutMs = 15000;

  static String _wsFromHttp(String httpUrl) {
    final uri = Uri.tryParse(httpUrl);
    if (uri == null || uri.host.isEmpty) {
      return 'ws://10.0.2.2:8082/ws/realtime';
    }
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port/ws/realtime';
  }

  static String _stripTrailingSlash(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
