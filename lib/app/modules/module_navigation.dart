import 'app_module.dart';
import 'module_url_resolver.dart';
import '../../modules/billetterie_module_registry.dart';
import '../../modules/immo_module_registry.dart';

/// Builds AppStack params for native or WebView modules.
class ModuleNavigation {
  ModuleNavigation._();

  static Map<String, Object?> openModuleParams(AppModule module) {
    if (ImmoModuleRegistry.isNativeImmo(module)) {
      return nativeModuleParams(module);
    }
    if (BilletterieModuleRegistry.isNativeBilletterie(module)) {
      return nativeModuleParams(module);
    }
    return webModuleParams(module);
  }

  static Map<String, Object?> nativeModuleParams(AppModule module) {
    return {
      'moduleId': module.id.toString(),
      'moduleKey': module.moduleKey,
      'title': module.name,
    };
  }

  static Map<String, Object?> webModuleParams(AppModule module) {
    final resolved = ModuleUrlResolver.resolve(module);
    return {
      'moduleId': module.id.toString(),
      'title': module.name,
      'url': resolved.url,
      'isAssetModule': resolved.isAssetModule,
      if (resolved.assetPath != null) 'assetPath': resolved.assetPath,
      'moduleKey': module.moduleKey,
      if (module.partnerId != null) 'partnerId': module.partnerId,
    };
  }
}
