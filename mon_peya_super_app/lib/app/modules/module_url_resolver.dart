import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_module.dart';

/// Resolves module URLs for local dev overrides (Vite apps on the LAN).
class ModuleUrlResolver {
  ModuleUrlResolver._();

  /// Single host for all immo Vite apps: `--dart-define=IMMO_DEV_HOST=192.168.x.x`
  static const immoDevHost = String.fromEnvironment('IMMO_DEV_HOST');

  /// Per-module overrides (optional):
  /// `--dart-define=RENTAL_MODULE_URL=http://192.168.x.x:3001`
  /// `--dart-define=CONSTRUCTION_MODULE_URL=http://192.168.x.x:3002`
  /// `--dart-define=COLLECTION_MODULE_URL=http://192.168.x.x:3003`
  static const rentalDevUrl = String.fromEnvironment('RENTAL_MODULE_URL');
  static const constructionDevUrl = String.fromEnvironment('CONSTRUCTION_MODULE_URL');
  static const collectionDevUrl = String.fromEnvironment('COLLECTION_MODULE_URL');

  static const _vitePorts = <String, int>{
    'real-estate': 3001,
    'construction': 3002,
    'collection': 3003,
  };

  static ResolvedModuleUrl resolve(AppModule module) {
    final devUrl = _devUrlFor(module.moduleKey);
    if (devUrl.isNotEmpty) {
      return ResolvedModuleUrl(
        url: devUrl,
        isAssetModule: false,
        assetPath: null,
      );
    }

    return ResolvedModuleUrl(
      url: module.url,
      isAssetModule: module.isAssetModule,
      assetPath: module.isAssetModule ? module.assetPath : null,
    );
  }

  static String _devUrlFor(String moduleKey) {
    final port = _vitePorts[moduleKey];
    if (port == null) return '';

    final explicit = switch (moduleKey) {
      'real-estate' => rentalDevUrl,
      'construction' => constructionDevUrl,
      'collection' => collectionDevUrl,
      _ => '',
    };
    if (explicit.isNotEmpty) {
      return _effectiveDevUrl(explicit, port);
    }

    if (immoDevHost.isNotEmpty) {
      final host = immoDevHost.replaceAll(RegExp(r'^https?://'), '').split('/').first;
      return _effectiveDevUrl('http://$host:$port', port);
    }

    return '';
  }

  static String _effectiveDevUrl(String configured, int port) {
    if (configured.isEmpty) return '';

    if (kDebugMode &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
        configured.contains(':$port')) {
      return 'http://localhost:$port';
    }

    return configured;
  }
}

class ResolvedModuleUrl {
  const ResolvedModuleUrl({
    required this.url,
    required this.isAssetModule,
    this.assetPath,
  });

  final String url;
  final bool isAssetModule;
  final String? assetPath;
}
