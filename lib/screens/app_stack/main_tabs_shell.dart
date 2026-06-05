import 'package:flutter/material.dart';

import 'tabs/home_screen.dart';
import 'tabs/peyapay_screen.dart';
import 'tabs/subscriptions_screen.dart';

enum MainTab { home, peyapay, subscriptions }

class MainTabsShell extends StatefulWidget {
  const MainTabsShell({super.key});

  @override
  State<MainTabsShell> createState() => _MainTabsShellState();
}

class _MainTabsShellState extends State<MainTabsShell> {
  MainTab _tab = MainTab.home;

  final _navKeys = <MainTab, GlobalKey<NavigatorState>>{
    MainTab.home: GlobalKey<NavigatorState>(),
    MainTab.peyapay: GlobalKey<NavigatorState>(),
    MainTab.subscriptions: GlobalKey<NavigatorState>(),
  };

  Future<bool> _onBackPressed() async {
    final nav = _navKeys[_tab]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }

    if (_tab != MainTab.home) {
      setState(() => _tab = MainTab.home);
      return false;
    }

    return true;
  }

  Future<void> _selectTab(MainTab next) async {
    if (next == _tab) {
      _navKeys[_tab]!.currentState!.popUntil((r) => r.isFirst);
      return;
    }

    setState(() => _tab = next);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onBackPressed();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _tab.index,
              children: [
                _TabNavigator(navigatorKey: _navKeys[MainTab.home]!, root: const HomeScreen()),
                _TabNavigator(
                  navigatorKey: _navKeys[MainTab.peyapay]!,
                  root: const PeyapayScreen(),
                ),
                _TabNavigator(
                  navigatorKey: _navKeys[MainTab.subscriptions]!,
                  root: const SubscriptionsScreen(),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (idx) => _selectTab(MainTab.values[idx]),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'HOME'),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'PEYAPAY',
            ),
            NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'MY SUBS'),
          ],
        ),
      ),
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

