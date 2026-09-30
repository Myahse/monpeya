import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';

class SimModuleRegistry {
  SimModuleRegistry._();

  static bool isNativeSim(AppModule module) {
    if (module.type == ModuleLaunchType.native && module.moduleKey == 'sim-assurance') {
      return true;
    }
    if (module.url.startsWith('native:sim')) return true;
    return module.moduleKey == 'sim-assurance';
  }

  static String? stackRouteFor(AppModule module) {
    if (!isNativeSim(module)) return null;
    return AppStackRoute.simAssurance;
  }
}
