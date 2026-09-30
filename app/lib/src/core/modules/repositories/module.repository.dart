import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/bundled.modules.dart';
import 'package:app/src/core/modules/config/module_visibility.config.dart';

class ModuleRepository {
  ModuleRepository._();

  static const shellTabModuleKeys = {'peyapay'};

  static List<AppModule> get modules {
    final list = ModuleVisibility.filterVisible(
      List<AppModule>.from(BundledModules.catalog),
    ).where((m) => !shellTabModuleKeys.contains(m.moduleKey)).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  static List<AppModule> get mockModules => modules;

  List<AppModule> fetchModules() => modules;
}
