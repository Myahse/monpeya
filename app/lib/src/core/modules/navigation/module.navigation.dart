import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/resolvers/module_url.resolver.dart';
import 'package:app/src/integration/registries/billetterie_module.registry.dart';
import 'package:app/src/integration/registries/grenier_module.registry.dart';
import 'package:app/src/integration/registries/immo_module.registry.dart';
import 'package:app/src/integration/registries/leadway_module.registry.dart';
import 'package:app/src/integration/registries/sim_module.registry.dart';

class ModuleNavigation {
  ModuleNavigation._();

  static Map<String, Object?> openModuleParams(AppModule module) {
    if (ImmoModuleRegistry.isNativeImmo(module)) {
      return nativeModuleParams(module);
    }
    if (BilletterieModuleRegistry.isNativeBilletterie(module)) {
      return nativeModuleParams(module);
    }
    if (LeadwayModuleRegistry.isNativeLeadway(module)) {
      return nativeModuleParams(module);
    }
    if (SimModuleRegistry.isNativeSim(module)) {
      return nativeModuleParams(module);
    }
    if (GrenierModuleRegistry.isNativeGrenier(module)) {
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
