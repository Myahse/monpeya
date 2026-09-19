import 'package:grenier/grenier.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';

class GrenierModuleRegistry {
  GrenierModuleRegistry._();

  static bool isNativeGrenier(AppModule module) {
    if (module.url.startsWith('native:grenier')) return true;
    return GrenierModuleKeys.isGrenierKey(module.moduleKey);
  }

  static String? stackRouteFor(AppModule module) {
    if (!isNativeGrenier(module)) return null;
    return AppStackRoute.monGrenier;
  }
}
