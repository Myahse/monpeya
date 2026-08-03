import 'package:billetterie/src/shared/config/billetterie_env.registry.dart';


class BilletterieApiConfig {
  static const _defineBaseUrl = String.fromEnvironment(
    'BILLETTERIE_API_URL',
    defaultValue: 'http://10.0.2.2:8082/api/billetterie',
  );

  static const _defineTransportBaseUrl = String.fromEnvironment(
    'BILLETTERIE_TRANSPORT_API_URL',
    defaultValue: '',
  );

  static const _defineEventBaseUrl = String.fromEnvironment(
    'BILLETTERIE_EVENT_API_URL',
    defaultValue: '',
  );

  static const _defineWsUrl = String.fromEnvironment(
    'BILLETTERIE_WS_URL',
    defaultValue: '',
  );

  static const apiTimeout = Duration(seconds: 20);

  /// Shared / legacy ticketing host (`BILLETTERIE_API_URL`).
  static String get baseUrl {
    final runtime = BilletterieEnvRegistry.baseUrl;
    if (runtime != null && runtime.isNotEmpty) {
      return _stripTrailingSlash(runtime);
    }
    return _stripTrailingSlash(_defineBaseUrl);
  }

  /// Transport ticketing host (falls back to [baseUrl]).
  static String get transportBaseUrl {
    final runtime = BilletterieEnvRegistry.transportBaseUrl;
    if (runtime != null && runtime.isNotEmpty) {
      return _stripTrailingSlash(runtime);
    }
    if (_defineTransportBaseUrl.trim().isNotEmpty) {
      return _stripTrailingSlash(_defineTransportBaseUrl);
    }
    return baseUrl;
  }

  /// Event ticketing host (falls back to [baseUrl]).
  static String get eventBaseUrl {
    final runtime = BilletterieEnvRegistry.eventBaseUrl;
    if (runtime != null && runtime.isNotEmpty) {
      return _stripTrailingSlash(runtime);
    }
    if (_defineEventBaseUrl.trim().isNotEmpty) {
      return _stripTrailingSlash(_defineEventBaseUrl);
    }
    return baseUrl;
  }

  /// Ticketing WebSocket URL (`BILLETTERIE_WS_URL`).
  ///
  /// Defaults to `ws(s)://{api-host}/ws` derived from [baseUrl].
  static String get wsUrl {
    final runtime = BilletterieEnvRegistry.wsUrl;
    if (runtime != null && runtime.isNotEmpty) {
      return runtime.trim();
    }
    if (_defineWsUrl.trim().isNotEmpty) {
      return _defineWsUrl.trim();
    }
    return _wsFromHttp(baseUrl);
  }

  static String _wsFromHttp(String httpUrl) {
    final uri = Uri.tryParse(httpUrl);
    if (uri == null || uri.host.isEmpty) {
      return 'ws://10.0.2.2:8090/ws';
    }
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port/ws';
  }

  static String _stripTrailingSlash(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
