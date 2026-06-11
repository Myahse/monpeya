import 'package:app/src/core/modules/app.module.dart';

/// Set to [true] when working locally on Billetterie / Mr Immo services.
const kShowWorkInProgressModules = false;

const _hiddenModuleKeys = <String>{
  'billetterie',
  'billetterie-electronique',
  'real-estate',
  'construction',
  'collection',
  'mr-immo-rental',
  'mr-immo-construction',
  'mr-immo-collection',
};

class ModuleVisibility {
  ModuleVisibility._();

  static bool isHiddenModuleKey(String moduleKey) {
    if (kShowWorkInProgressModules) return false;
    return _hiddenModuleKeys.contains(moduleKey);
  }

  static bool isHiddenModule(AppModule module) => isHiddenModuleKey(module.moduleKey);

  static List<AppModule> filterVisible(List<AppModule> modules) {
    if (kShowWorkInProgressModules) return modules;
    return [
      for (final module in modules)
        if (!isHiddenModule(module)) module,
    ];
  }
}
