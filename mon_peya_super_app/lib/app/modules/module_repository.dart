import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/auth_store.dart';
import 'app_module.dart';
import 'bundled_modules.dart';
import 'module_api_config.dart';
import 'module_merger.dart';

class ModuleRepository {
  ModuleRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Backward-compatible alias for bundled catalog.
  static List<AppModule> get mockModules => BundledModules.catalog;

  Future<ModuleFetchResult> fetchModulesResult() async {
    final mode = ModuleApiConfig.loadMode;
    final bundled = List<AppModule>.from(BundledModules.catalog);

    if (mode == ModuleLoadMode.bundledOnly) {
      return ModuleFetchResult(
        modules: ModuleMerger.merge(mode: mode, remote: const [], bundled: bundled),
        loadMode: mode,
        apiReachable: false,
        usedBundledFallback: true,
        stats: ModuleFetchStats.fromModules(bundled),
      );
    }

    try {
      final remote = await _fetchFromApi();
      final merged = ModuleMerger.merge(mode: mode, remote: remote, bundled: bundled);
      return ModuleFetchResult(
        modules: merged,
        loadMode: mode,
        apiReachable: true,
        usedBundledFallback: false,
        stats: ModuleFetchStats.fromModules(merged),
      );
    } catch (_) {
      if (mode == ModuleLoadMode.remoteOnly) {
        rethrow;
      }

      final fallback = ModuleMerger.merge(
        mode: ModuleLoadMode.bundledOnly,
        remote: const [],
        bundled: bundled,
      );
      return ModuleFetchResult(
        modules: fallback,
        loadMode: mode,
        apiReachable: false,
        usedBundledFallback: true,
        stats: ModuleFetchStats.fromModules(fallback),
      );
    }
  }

  Future<List<AppModule>> fetchModules() async {
    final result = await fetchModulesResult();
    return result.modules;
  }

  Future<List<AppModule>> _fetchFromApi() async {
    final uri = Uri.parse('${ModuleApiConfig.baseUrl}${ModuleApiConfig.modulesPath}');
    final headers = <String, String>{'Accept': 'application/json'};

    final token = await AuthStore.authToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw ModuleFetchException('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ModulesResponse.fromJson(json).modules;
  }
}

class ModuleFetchException implements Exception {
  ModuleFetchException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ModuleFetchResult {
  const ModuleFetchResult({
    required this.modules,
    required this.loadMode,
    required this.apiReachable,
    required this.usedBundledFallback,
    required this.stats,
  });

  final List<AppModule> modules;
  final ModuleLoadMode loadMode;
  final bool apiReachable;
  final bool usedBundledFallback;
  final ModuleFetchStats stats;
}
