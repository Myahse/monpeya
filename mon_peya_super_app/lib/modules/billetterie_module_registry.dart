import '../app/modules/app_module.dart';
import '../screens/app_stack/app_stack_types.dart';

/// Super-app adapter — maps catalog entries to Billetterie native route.
class BilletterieModuleRegistry {
  BilletterieModuleRegistry._();

  static bool isNativeBilletterie(AppModule module) {
    if (module.type == ModuleLaunchType.native && module.moduleKey == 'billetterie') {
      return true;
    }
    if (module.url.startsWith('native:billetterie')) return true;
    return module.moduleKey == 'billetterie';
  }

  static String? stackRouteFor(AppModule module) {
    if (!isNativeBilletterie(module)) return null;
    return AppStackRoute.billetterie;
  }
}
