import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';

/// Super-app adapter — maps catalog entries to Leadway Assurance native route.
class LeadwayModuleRegistry {
  LeadwayModuleRegistry._();

  static bool isNativeLeadway(AppModule module) {
    if (module.type == ModuleLaunchType.native && module.moduleKey == 'leadway-assurance') {
      return true;
    }
    if (module.url.startsWith('native:leadway')) return true;
    return module.moduleKey == 'leadway-assurance';
  }

  static String? stackRouteFor(AppModule module) {
    if (!isNativeLeadway(module)) return null;
    return AppStackRoute.leadwayAssurance;
  }
}
