import 'app_module.dart';

class ModuleApiConfig {
  ModuleApiConfig._();

  /// `--dart-define=API_BASE_URL=https://api.djogana.com`
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.djogana.com',
  );

  static const modulesPath = '/api/modules';

  /// `--dart-define=RENTAL_API_URL=http://192.168.x.x:8081`
  /// When empty, embedded rental uses the Vite origin (proxy to :8081).
  static const rentalApiUrl = String.fromEnvironment('RENTAL_API_URL');

  static const _immoVitePorts = {3001, 3002, 3003};

  /// API base passed into embedded web modules (`apiBase` query param).
  static String? apiBaseForModuleUrl(String moduleUrl) {
    if (rentalApiUrl.isNotEmpty) return rentalApiUrl;
    final uri = Uri.tryParse(moduleUrl);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return 'http://${uri.host}:8081';
    }
    // Mr Immo Vite dev servers proxy /api → Spring Boot on the dev machine.
    if (uri.hasPort && _immoVitePorts.contains(uri.port)) {
      return uri.origin;
    }
    return 'http://${uri.host}:8081';
  }

  /// `--dart-define=MODULE_LOAD_MODE=hybrid|bundled|remote`
  ///
  /// | Mode | Use case |
  /// |------|----------|
  /// | hybrid (default) | Production — API + bundled, partners can add modules |
  /// | bundled | Dev / demo — no API call, fastest builds |
  /// | remote | API only — no bundled tiles |
  static final loadMode = ModuleLoadModeParsing.fromString(
    const String.fromEnvironment('MODULE_LOAD_MODE', defaultValue: 'hybrid'),
  );

  static bool get isBundledOnly => loadMode == ModuleLoadMode.bundledOnly;
  static bool get mergesBundledModules => loadMode != ModuleLoadMode.remoteOnly;
}
