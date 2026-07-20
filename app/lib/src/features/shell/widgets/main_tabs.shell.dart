import 'package:flutter/material.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/features/shell/controllers/app_stack.controller.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/shell/scopes/main_tabs.scope.dart';
import 'package:app/src/features/shell/tabs/screens/home.screen.dart';
import 'package:app/src/features/shell/tabs/screens/peyapay_tab.shell.dart';
import 'package:app/src/features/shell/tabs/screens/subscriptions.screen.dart';
import 'package:app/src/features/shell/widgets/main_bottom_navigation_bar.widget.dart';

enum MainTab { home, peyapay, subscriptions }

class MainTabsShell extends StatefulWidget {
  const MainTabsShell({super.key});

  static const storageKey = PageStorageKey<String>('main-tabs-shell');

  @override
  State<MainTabsShell> createState() => _MainTabsShellState();
}

class _MainTabsShellState extends State<MainTabsShell> {
  MainTab _tab = MainTab.home;
  AppStackController? _appStack;

  final _navKeys = <MainTab, GlobalKey<NavigatorState>>{
    MainTab.home: GlobalKey<NavigatorState>(),
    MainTab.peyapay: GlobalKey<NavigatorState>(),
    MainTab.subscriptions: GlobalKey<NavigatorState>(),
  };

  bool _handleMainTabBack() {
    final nav = _navKeys[_tab]!.currentState;
    if (nav == null) return false;
    if (nav.canPop()) {
      nav.pop();
      return true;
    }

    if (_tab != MainTab.home) {
      setState(() => _tab = MainTab.home);
      return true;
    }

    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stack = AppStackScope.maybeOf(context);
    if (_appStack != null && _appStack!.onMainBack == _handleMainTabBack) {
      _appStack!.onMainBack = null;
    }
    _appStack = stack;
    _appStack?.onMainBack = _handleMainTabBack;
  }

  @override
  void dispose() {
    if (_appStack?.onMainBack == _handleMainTabBack) {
      _appStack!.onMainBack = null;
    }
    super.dispose();
  }

  Future<void> _selectTab(MainTab next) async {
    if (next == _tab) {
      _navKeys[_tab]!.currentState!.popUntil((r) => r.isFirst);
      return;
    }

    if (next == MainTab.peyapay) {
      final ok = await ModuleAuth.ensureRegistered(context);
      if (!ok || !mounted) return;
    }

    setState(() => _tab = next);
  }

  bool _hideBottomNav() => MonPeyaSession.instance.isAuthOverlayVisible;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MonPeyaSession.instance,
      builder: (context, _) {
        final hideNav = _hideBottomNav();
        return MainTabsScope(
          selectTab: _selectTab,
          child: Scaffold(
            extendBody: hideNav,
            extendBodyBehindAppBar: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: IndexedStack(
                  index: _tab.index,
                  children: [
                    _TabNavigator(navigatorKey: _navKeys[MainTab.home]!, root: const HomeScreen()),
                    _TabNavigator(
                      navigatorKey: _navKeys[MainTab.peyapay]!,
                      root: const PeyapayTabShell(),
                    ),
                    _TabNavigator(
                      navigatorKey: _navKeys[MainTab.subscriptions]!,
                      root: const SubscriptionsScreen(),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: hideNav
                ? null
                : MainBottomNavigationBar(
                    selectedIndex: _tab.index,
                    onDestinationSelected: (idx) => _selectTab(MainTab.values[idx]),
                  ),
          ),
        );
      },
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({required this.navigatorKey, required this.root});
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => root,
      ),
    );
  }
}
