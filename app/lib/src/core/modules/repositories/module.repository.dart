import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/bundled.modules.dart';
import 'package:app/src/core/modules/config/module_visibility.config.dart';

/// Local mock catalog — no remote API.
class ModuleRepository {
  ModuleRepository._();

  /// Modules with a dedicated shell tab — hidden from service grids and menus.
  static const shellTabModuleKeys = {'peyapay'};

  static List<AppModule> get modules => ModuleVisibility.filterVisible(
        List<AppModule>.from(BundledModules.catalog),
      ).where((m) => !shellTabModuleKeys.contains(m.moduleKey)).toList();

  /// Backward-compatible alias.
  static List<AppModule> get mockModules => modules;

  List<AppModule> fetchModules() => modules;
}
