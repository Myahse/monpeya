import 'package:billetterie/src/shared/config/billetterie_env.registry.dart';

/// Base URLs and timeouts for Billetterie ticketing backends.
///
/// Transport and event may share one host today, or use distinct URLs later.
class BilletterieApiConfig {
  static const _defineBaseUrl = String.fromEnvironment(
    'BILLETTERIE_API_URL',
    defaultValue: 'http://10.0.2.2:8090',
  );

  static const _defineTransportBaseUrl = String.fromEnvironment(
    'BILLETTERIE_TRANSPORT_API_URL',
    defaultValue: '',
  );

  static const _defineEventBaseUrl = String.fromEnvironment(
    'BILLETTERIE_EVENT_API_URL',
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

  static String _stripTrailingSlash(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
