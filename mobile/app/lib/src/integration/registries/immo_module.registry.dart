import 'package:immo/immo.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';

/// Super-app adapter — maps catalog entries to Mr Immo native routes.
class ImmoModuleRegistry {
  ImmoModuleRegistry._();

  static bool isNativeImmo(AppModule module) {
    if (module.type == ModuleLaunchType.native) return true;
    if (module.url.startsWith('native:immo/')) return true;
    return ImmoModuleKeys.isImmoKey(module.moduleKey);
  }

  static String? stackRouteFor(AppModule module) {
    if (!isNativeImmo(module)) return null;
    return switch (module.moduleKey) {
      ImmoModuleKeys.rental || 'rental' => AppStackRoute.mrImmoRental,
      ImmoModuleKeys.construction => AppStackRoute.mrImmoConstruction,
      ImmoModuleKeys.collection => AppStackRoute.mrImmoCollection,
      _ => null,
    };
  }
}
