import 'package:flutter/widgets.dart';

import 'package:app/src/features/shell/widgets/main_tabs.shell.dart';

typedef MainTabSelector = Future<void> Function(MainTab tab);

/// Lets service tiles switch the main bottom tab (e.g. Peya Pay).
class MainTabsScope extends InheritedWidget {
  const MainTabsScope({
    required this.selectTab,
    required super.child,
    super.key,
  });

  final MainTabSelector selectTab;

  static MainTabSelector? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainTabsScope>()?.selectTab;

  @override
  bool updateShouldNotify(MainTabsScope oldWidget) => selectTab != oldWidget.selectTab;
}
