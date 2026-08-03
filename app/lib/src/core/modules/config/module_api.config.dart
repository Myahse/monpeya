
class ModuleApiConfig {
  ModuleApiConfig._();

  static const rentalApiUrl = String.fromEnvironment('RENTAL_API_URL');

  static const _immoVitePorts = {3001, 3002, 3003};

  static String? apiBaseForModuleUrl(String moduleUrl) {
    if (rentalApiUrl.isNotEmpty) return rentalApiUrl;
    final uri = Uri.tryParse(moduleUrl);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return 'http://${uri.host}:8081';
    }
    if (uri.hasPort && _immoVitePorts.contains(uri.port)) {
      return uri.origin;
    }
    return 'http://${uri.host}:8081';
  }
}
