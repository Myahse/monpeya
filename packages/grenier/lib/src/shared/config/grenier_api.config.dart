import 'package:grenier/src/shared/config/grenier_env.registry.dart';

abstract final class GrenierApiConfig {
  static const _defineBaseUrl = String.fromEnvironment(
    'GRENIER_API_URL',
    defaultValue: 'http://10.0.2.2:8083',
  );

  static const _defineWsUrl = String.fromEnvironment(
    'GRENIER_WS_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final runtime = GrenierEnvRegistry.baseUrl;
    if (runtime != null && runtime.isNotEmpty) {
      return _strip(runtime);
    }
    return _strip(_defineBaseUrl);
  }

  static String get wsUrl {
    final runtime = GrenierEnvRegistry.wsUrl;
    if (runtime != null && runtime.isNotEmpty) return runtime.trim();
    if (_defineWsUrl.trim().isNotEmpty) return _defineWsUrl.trim();
    return _wsFromHttp(baseUrl);
  }

  static String _wsFromHttp(String httpUrl) {
    final uri = Uri.tryParse(httpUrl);
    if (uri == null || uri.host.isEmpty) {
      return 'ws://10.0.2.2:8083/ws/realtime';
    }
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port/ws/realtime';
  }

  static String _strip(String url) {
    var v = url.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}
