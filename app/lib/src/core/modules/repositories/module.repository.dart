import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/bundled.modules.dart';
import 'package:app/src/core/modules/config/module_visibility.config.dart';

/// Local mock catalog — no remote API.
class ModuleRepository {
  const ModuleRepository();

  static List<AppModule> get modules => ModuleVisibility.filterVisible(
        List<AppModule>.from(BundledModules.catalog),
      );

  /// Backward-compatible alias.
  static List<AppModule> get mockModules => modules;

  List<AppModule> fetchModules() => modules;
}
