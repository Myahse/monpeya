import 'package:flutter/foundation.dart';

import 'app_stack_types.dart';

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

  void navigateToMain() {
    final next = [
      ...value.stack,
      AppStackItem(
        id: 'main-${DateTime.now().millisecondsSinceEpoch}',
        name: AppStackRoute.main,
        params: const {},
      ),
    ];
    value = AppStackState(stack: next, menuVisible: false);
  }

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

  void goBack() {
    if (value.stack.length <= 1) return;
    value = AppStackState(
      stack: value.stack.sublist(0, value.stack.length - 1),
      menuVisible: false,
    );
  }
}

