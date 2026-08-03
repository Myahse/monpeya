import 'dart:async';

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
import 'package:peyapay/peyapay.dart';

enum MainTab { home, peyapay, subscriptions }

class MainTabsShell extends StatefulWidget {
  const MainTabsShell({super.key});

  static const storageKey = PageStorageKey<String>('main-tabs-shell');

  @override
  State<MainTabsShell> createState() => _MainTabsShellState();
}

class _MainTabsShellState extends State<MainTabsShell>
    with SingleTickerProviderStateMixin {
  MainTab _tab = MainTab.home;
  AppStackController? _appStack;

  final _navKeys = <MainTab, GlobalKey<NavigatorState>>{
    MainTab.home: GlobalKey<NavigatorState>(),
    MainTab.peyapay: GlobalKey<NavigatorState>(),
    MainTab.subscriptions: GlobalKey<NavigatorState>(),
  };

  final _peyapayReveal = PeyapayHomeRevealController();

  late final AnimationController _navEnter;
  late final Animation<double> _navFade;
  late final Animation<Offset> _navSlide;

  @override
  void initState() {
    super.initState();
    _navEnter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    final curve = CurvedAnimation(
      parent: _navEnter,
      curve: const Interval(0.62, 1.0, curve: Curves.easeOutCubic),
    );
    _navFade = curve;
    _navSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navEnter.forward();
    });
  }

  bool _handleMainTabBack() {
    final nav = _navKeys[_tab]!.currentState;
    if (nav == null) return false;
    if (nav.canPop()) {
      nav.pop();
      return true;
    }

    if (_tab != MainTab.home) {
      // Animate PeyaPay actions card closed before leaving the tab.
      if (_tab == MainTab.peyapay) {
        unawaited(_leavePeyapayToHome());
        return true;
      }
      setState(() => _tab = MainTab.home);
      return true;
    }

    return false;
  }

  Future<void> _leavePeyapayToHome() async {
    await _peyapayReveal.playExit();
    if (!mounted) return;
    setState(() => _tab = MainTab.home);
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
    _navEnter.dispose();
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

    // Play actions-card exit before IndexedStack hides PeyaPay.
    if (_tab == MainTab.peyapay && next != MainTab.peyapay) {
      await _peyapayReveal.playExit();
      if (!mounted) return;
    }

    setState(() => _tab = next);

    if (next == MainTab.peyapay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _peyapayReveal.playEnter();
      });
    }
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
            extendBodyBehindAppBar: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IndexedStack(
                        index: _tab.index,
                        children: [
                          _TabNavigator(
                            navigatorKey: _navKeys[MainTab.home]!,
                            root: const HomeScreen(),
                          ),
                          _TabNavigator(
                            navigatorKey: _navKeys[MainTab.peyapay]!,
                            root: PeyapayTabShell(
                              revealController: _peyapayReveal,
                            ),
                          ),
                          _TabNavigator(
                            navigatorKey: _navKeys[MainTab.subscriptions]!,
                            root: const SubscriptionsScreen(),
                          ),
                        ],
                      ),
                    ),
                    if (!hideNav)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: FadeTransition(
                          opacity: _navFade,
                          child: SlideTransition(
                            position: _navSlide,
                            child: MainBottomNavigationBar(
                              selectedIndex: _tab.index,
                              onDestinationSelected: (idx) =>
                                  _selectTab(MainTab.values[idx]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
