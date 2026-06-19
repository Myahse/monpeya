import 'package:flutter/foundation.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/navigation/module.navigation.dart';
import 'package:app/src/integration/registries/billetterie_module.registry.dart';
import 'package:app/src/integration/registries/immo_module.registry.dart';
import 'package:app/src/integration/registries/leadway_module.registry.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';

class AppStackController extends ValueNotifier<AppStackState> {
  AppStackController()
      : super(
          AppStackState(
            stack: [AppStackItem(id: 'main-0', name: AppStackRoute.main, params: const {})],
            menuVisible: false,
          ),
        );

  bool get canGoBack => value.stack.length > 1;

  void toggleMenu() =>
      value = AppStackState(stack: value.stack, menuVisible: !value.menuVisible);

  /// Returns to Mon Peya home (main tabs) — does not stack another Main route.
  void popToHome() {
    value = AppStackState(
      stack: [value.stack.first],
      menuVisible: false,
    );
  }

  void navigateToMain() => popToHome();

  void openService(String name, {Map<String, Object?> params = const {}}) {
    final next = [
      ...value.stack,
      AppStackItem(
        id: '$name-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        params: params,
      ),
    ];
    value = AppStackState(stack: next, menuVisible: false);
  }

  /// Opens a native or web module from home; switches module when already inside one.
  void openModule(AppModule module) {
    final nativeRoute = ImmoModuleRegistry.stackRouteFor(module) ??
        BilletterieModuleRegistry.stackRouteFor(module) ??
        LeadwayModuleRegistry.stackRouteFor(module);
    final routeName = nativeRoute ?? AppStackRoute.webModule;
    final params = ModuleNavigation.openModuleParams(module);
    final item = AppStackItem(
      id: '${module.moduleKey}-${DateTime.now().millisecondsSinceEpoch}',
      name: routeName,
      params: params,
    );

    if (AppStackRoute.isModuleRoute(value.current.name)) {
      final base = value.stack.sublist(0, value.stack.length - 1);
      value = AppStackState(stack: [...base, item], menuVisible: false);
      return;
    }

    value = AppStackState(stack: [...value.stack, item], menuVisible: false);
  }

  void goBack() {
    if (value.stack.length <= 1) return;
    value = AppStackState(
      stack: value.stack.sublist(0, value.stack.length - 1),
      menuVisible: false,
    );
  }
}
