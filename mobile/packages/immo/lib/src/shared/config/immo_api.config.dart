import 'package:immo/src/shared/config/immo_env.registry.dart';

/// API configuration shared across Mr Immo Flutter modules.
abstract final class ImmoApiConfig {
  static String get baseUrl {
    final runtime = ImmoEnvRegistry.baseUrl;
    if (runtime != null && runtime.isNotEmpty) return runtime;

    return const String.fromEnvironment(
      'IMMO_API_URL',
      defaultValue: String.fromEnvironment(
        'RENTAL_API_URL',
        defaultValue: String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8082/api/immo',
        ),
      ),
    );
  }

  static const timeoutMs = 15000;
}
