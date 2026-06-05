import 'package:flutter/widgets.dart';

import 'app_stack_controller.dart';

class AppStackScope extends InheritedWidget {
  const AppStackScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final AppStackController controller;

  static AppStackController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStackScope>();
    if (scope == null) throw StateError('AppStackScope not found');
    return scope.controller;
  }

  static AppStackController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStackScope>()?.controller;

  @override
  bool updateShouldNotify(AppStackScope oldWidget) => controller != oldWidget.controller;
}

