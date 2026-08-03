import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/bundled.modules.dart';
import 'package:app/src/core/modules/config/module_visibility.config.dart';

class ModuleRepository {
  ModuleRepository._();

  static const shellTabModuleKeys = {'peyapay'};

  static List<AppModule> get modules => ModuleVisibility.filterVisible(
        List<AppModule>.from(BundledModules.catalog),
      ).where((m) => !shellTabModuleKeys.contains(m.moduleKey)).toList();

  static List<AppModule> get mockModules => modules;

  List<AppModule> fetchModules() => modules;
}
