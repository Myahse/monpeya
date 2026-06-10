import 'package:flutter/widgets.dart';

import 'app/app.dart';

void main() => runApp(const MonPeyaSuperApp());

/*
import 'package:flutter/widgets.dart';

import 'app/app.dart';

void main() => runApp(const MonPeyaSuperApp());

import 'package:flutter/widgets.dart';

import 'app/app.dart';

void main() => runApp(const MonPeyaSuperApp());

import 'package:flutter/material.dart';

import 'app/app.dart';

void main() => runApp(const MonPeyaSuperApp());

/// Native multi-step registration wrapper (RN `RegistrationWrapperScreen` equivalent).
class RegistrationFlowScreen extends StatefulWidget {
  const RegistrationFlowScreen({super.key});
  static const routeName = '/registration-flow';

  @override
  State<RegistrationFlowScreen> createState() => _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState extends State<RegistrationFlowScreen> {
  int _step = 0;
  bool _busy = false;

  Future<void> _next() async {
    if (_busy) return;
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }

    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefsKeys.isRegistered, true);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushReplacementNamed(AppStackScreen.routeName);
  }

  Future<void> _back() async {
    if (_busy) return;
    if (_step == 0) {
      Navigator.of(context).pushReplacementNamed(PhoneInputScreen.routeName);
      return;
    }
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final stepTitle = switch (_step) {
      0 => 'Identity',
      1 => 'Verify',
      _ => 'Set PIN',
    };

    final stepBody = switch (_step) {
      0 => const Text('Step 1: capture identity details (placeholder).'),
      1 => const Text('Step 2: verify phone/OTP (placeholder).'),
      _ => const Text('Step 3: create your PIN (placeholder).'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Registration • $stepTitle'),
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_step + 1) / 3),
            const SizedBox(height: 16),
            stepBody,
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _next,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_step < 2 ? 'Next' : 'Finish'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});
  static const routeName = '/registration';

  @override
  Widget build(BuildContext context) {
    // Kept for route-compat; forward to the real flow.
    return const RegistrationFlowScreen();
  }
}

class LoginPinScreen extends StatelessWidget {
  const LoginPinScreen({super.key});
  static const routeName = '/login-pin';

  @override
  Widget build(BuildContext context) {
    return const _SimpleScaffold(title: 'Login PIN', body: Text('Login PIN placeholder.'));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'Settings',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Settings placeholder.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed(ResetPinScreen.routeName),
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }
}

class ResetPinScreen extends StatelessWidget {
  const ResetPinScreen({super.key});
  static const routeName = '/reset-pin';

  @override
  Widget build(BuildContext context) {
    return const _SimpleScaffold(title: 'Reset PIN', body: Text('Reset PIN placeholder.'));
  }
}


class AppStackScreen extends StatefulWidget {
  const AppStackScreen({super.key});
  static const routeName = '/app';

  @override
  State<AppStackScreen> createState() => _AppStackScreenState();
}

class _AppStackScreenState extends State<AppStackScreen> {
  final _controller = AppStackController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStackScope(
      controller: _controller,
      child: ValueListenableBuilder<AppStackState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          final active = state.current;
          final activeName = active.name;

          final activeScreen = switch (activeName) {
            AppStackRoute.main => const MainTabsShell(),
            AppStackRoute.billetterie => const BilletterieModuleScreen(),
            AppStackRoute.mrImmoRental => MrImmoRentalScreen(moduleId: (active.params['moduleId'] as String?) ?? ''),
            AppStackRoute.mrImmoConstruction => MrImmoConstructionScreen(moduleId: (active.params['moduleId'] as String?) ?? ''),
            AppStackRoute.mrImmoCollection => MrImmoCollectionScreen(moduleId: (active.params['moduleId'] as String?) ?? ''),
            AppStackRoute.serviceModule => ServiceModuleScreen(
                moduleId: (active.params['moduleId'] as String?) ?? '',
                bundleUrl: active.params['bundleUrl'] as String?,
              ),
            _ => const MainTabsShell(),
          };

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_controller.canGoBack) {
                _controller.goBack();
                return;
              }
              Navigator.of(context).pop();
            },
            child: Stack(
              children: [
                activeScreen,
                if (state.menuVisible) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _controller.toggleMenu,
                      child: Container(color: Colors.black.withValues(alpha: 0.35)),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _NteriMenuSheet(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

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
    if (next == MainTab.peyapay) {
      // RN behavior: check AsyncStorage at tap-time; if not registered → go Home then push Registration on root stack.
      final prefs = await SharedPreferences.getInstance();
      final ok = prefs.getBool(_PrefsKeys.isRegistered) ?? false;
      if (!ok) {
        setState(() => _tab = MainTab.home);
        _rootNavKey.currentState?.pushNamed(RegistrationScreen.routeName);
        return;
      }
    }

    if (next == _tab) {
      _navKeys[_tab]!.currentState!.popUntil((r) => r.isFirst);
      return;
    }

    setState(() => _tab = next);
  }

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.maybeOf(context);
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
                _TabNavigator(
                  navigatorKey: _navKeys[MainTab.home]!,
                  root: const HomeScreen(),
                ),
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
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom + 56,
              child: FloatingActionButton.extended(
                onPressed: () => appStack?.toggleMenu(),
                icon: const Icon(Icons.apps),
                label: const Text('NTERI'),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (idx) => _selectTab(MainTab.values[idx]),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'HOME'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'PEYAPAY'),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.maybeOf(context);
    return _ModuleScaffold(
      title: 'Home',
      children: [
        const _ModuleHeader(
          title: 'Mon Peya',
          subtitle: 'Super app shell (Flutter)',
        ),
        _ModuleTile(
          icon: Icons.confirmation_number_outlined,
          title: 'Billetterie',
          subtitle: 'Open integrated module',
          onTap: () => appStack?.openService(
            AppStackRoute.billetterie,
            params: const {'moduleId': 'billetterie-electronique'},
          ),
        ),
        _ModuleTile(
          icon: Icons.apartment_outlined,
          title: 'Mr Immo (Rental)',
          subtitle: 'Open integrated module',
          onTap: () => appStack?.openService(
            AppStackRoute.mrImmoRental,
            params: const {'moduleId': 'mr-immo-rental'},
          ),
        ),
      ],
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'Wallet',
      children: [
        const _ModuleHeader(title: 'Wallet', subtitle: 'Balance, top-up, history'),
        _ModuleTile(
          icon: Icons.add_card_outlined,
          title: 'Top up',
          subtitle: 'Add money to your wallet',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'Top up')),
          ),
        ),
        _ModuleTile(
          icon: Icons.receipt_long_outlined,
          title: 'Transactions',
          subtitle: 'View wallet history',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PlaceholderScreen(title: 'Transactions'),
            ),
          ),
        ),
      ],
    );
  }
}

class PayScreen extends StatelessWidget {
  const PayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'Pay',
      children: [
        const _ModuleHeader(title: 'Pay', subtitle: 'QR, send money, bills'),
        _ModuleTile(
          icon: Icons.qr_code_scanner_outlined,
          title: 'Scan QR',
          subtitle: 'Pay a merchant or friend',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'Scan QR')),
          ),
        ),
        _ModuleTile(
          icon: Icons.send_outlined,
          title: 'Send money',
          subtitle: 'Transfer to another user',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PlaceholderScreen(title: 'Send money'),
            ),
          ),
        ),
      ],
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'Services',
      children: [
        const _ModuleHeader(
          title: 'Services',
          subtitle: 'Modules inside the super app',
        ),
        _ModuleTile(
          icon: Icons.shopping_bag_outlined,
          title: 'Marketplace',
          subtitle: 'Browse, cart, checkout',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PlaceholderScreen(title: 'Marketplace'),
            ),
          ),
        ),
        _ModuleTile(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          subtitle: 'Help center and chat',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'Support')),
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'Profile',
      children: [
        const _ModuleHeader(title: 'Profile', subtitle: 'Account and settings'),
        _ModuleTile(
          icon: Icons.manage_accounts_outlined,
          title: 'Account',
          subtitle: 'Personal info, security',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'Account')),
          ),
        ),
        _ModuleTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Preferences',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'Settings')),
          ),
        ),
      ],
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title (placeholder)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _ModuleScaffold extends StatelessWidget {
  const _ModuleScaffold({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(pinned: true, title: Text(title)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(delegate: SliverChildListDelegate.fixed(children)),
          ),
        ],
      ),
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primaryContainer, cs.surfaceContainerHighest]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class PeyapayScreen extends StatelessWidget {
  const PeyapayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'PEYAPAY',
      children: [
        const _ModuleHeader(title: 'Peyapay', subtitle: 'Wallet + payments module'),
        _ModuleTile(
          icon: Icons.swap_horiz_outlined,
          title: 'Transfer',
          subtitle: 'Send money',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PlaceholderScreen(title: 'Transfer'),
            ),
          ),
        ),
        _ModuleTile(
          icon: Icons.receipt_long_outlined,
          title: 'Transactions',
          subtitle: 'Payment history',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PlaceholderScreen(title: 'Transactions'),
            ),
          ),
        ),
      ],
    );
  }
}

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.maybeOf(context);
    return _ModuleScaffold(
      title: 'MY SUBS',
      children: [
        const _ModuleHeader(title: 'My subscriptions', subtitle: 'Services you subscribed to'),
        _ModuleTile(
          icon: Icons.grid_view_outlined,
          title: 'My services',
          subtitle: 'Open service modules',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PlaceholderScreen(title: 'My services'),
            ),
          ),
        ),
        _ModuleTile(
          icon: Icons.widgets_outlined,
          title: 'Service module (generic)',
          subtitle: 'Loads a module by moduleId + bundleUrl',
          onTap: () => appStack?.openService(
            AppStackRoute.serviceModule,
            params: const {'moduleId': 'demo-module', 'bundleUrl': 'https://example.com/bundle.js'},
          ),
        ),
      ],
    );
  }
}

class _SimpleScaffold extends StatelessWidget {
  const _SimpleScaffold({required this.title, required this.body});
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}

class _PrefsKeys {
  static const seenOnboarding = 'seenOnboarding';
  static const isRegistered = 'isRegistered';
  static const phoneNumber = 'phoneNumber';
}

// === 

class AppStackRoute {
  static const main = 'Main';
  static const billetterie = 'Billetterie';
  static const mrImmoRental = 'MrImmoRental';
  static const mrImmoConstruction = 'MrImmoConstruction';
  static const mrImmoCollection = 'MrImmoCollection';
  static const serviceModule = 'ServiceModule';
}

class AppStackItem {
  AppStackItem({
    required this.id,
    required this.name,
    required this.params,
  });

  final String id;
  final String name;
  final Map<String, Object?> params;
}

class AppStackState {
  const AppStackState({
    required this.stack,
    required this.menuVisible,
  });

  final List<AppStackItem> stack;
  final bool menuVisible;

  AppStackItem get current => stack.isNotEmpty ? stack.last : AppStackItem(id: 'main-0', name: AppStackRoute.main, params: const {});
}

class AppStackController extends ValueNotifier<AppStackState> {
  AppStackController()
      : super(
          AppStackState(
            stack: [
              AppStackItem(id: 'main-0', name: AppStackRoute.main, params: const {}),
            ],
            menuVisible: false,
          ),
        );

  bool get canGoBack => value.stack.length > 1;

  void toggleMenu() => value = AppStackState(stack: value.stack, menuVisible: !value.menuVisible);

  void navigateToMain() {
    final next = [...value.stack, AppStackItem(id: 'main-${DateTime.now().millisecondsSinceEpoch}', name: AppStackRoute.main, params: const {})];
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
    value = AppStackState(stack: value.stack.sublist(0, value.stack.length - 1), menuVisible: false);
  }
}

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

class _NteriMenuSheet extends StatelessWidget {
  const _NteriMenuSheet();

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.of(context);

    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.home_outlined,
        label: 'Tableau de bord',
        onTap: appStack.navigateToMain,
      ),
      (
        icon: Icons.confirmation_number_outlined,
        label: 'Billetterie',
        onTap: () => appStack.openService(
          AppStackRoute.billetterie,
          params: const {'moduleId': 'billetterie-electronique'},
        ),
      ),
      (
        icon: Icons.apartment_outlined,
        label: 'Mr Immo (Rental)',
        onTap: () => appStack.openService(
          AppStackRoute.mrImmoRental,
          params: const {'moduleId': 'mr-immo-rental'},
        ),
      ),
      (
        icon: Icons.widgets_outlined,
        label: 'ServiceModule',
        onTap: () => appStack.openService(
          AppStackRoute.serviceModule,
          params: const {'moduleId': 'demo-module', 'bundleUrl': 'https://example.com/bundle.js'},
        ),
      ),
      (
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => _rootNavKey.currentState?.pushNamed(SettingsScreen.routeName),
      ),
    ];

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: appStack.canGoBack ? appStack.goBack : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Expanded(
                  child: Text(
                    "N'TERI",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
                IconButton(
                  onPressed: appStack.toggleMenu,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: [
                for (final item in items)
                  InkWell(
                    onTap: () {
                      appStack.toggleMenu();
                      item.onTap();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 28),
                          const SizedBox(height: 8),
                          Text(item.label, textAlign: TextAlign.center, maxLines: 2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceScaffold extends StatelessWidget {
  const _ServiceScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: appStack.goBack,
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.apps),
            onPressed: appStack.toggleMenu,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class BilletterieScreen extends StatelessWidget {
  const BilletterieScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Billetterie',
      child: Text('Billetterie moduleId=$moduleId (placeholder)'),
    );
  }
}

class MrImmoRentalScreen extends StatelessWidget {
  const MrImmoRentalScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Mr Immo Rental',
      child: Text('Mr Immo Rental moduleId=$moduleId (placeholder)'),
    );
  }
}

class MrImmoConstructionScreen extends StatelessWidget {
  const MrImmoConstructionScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Mr Immo Construction',
      child: Text('Mr Immo Construction moduleId=$moduleId (placeholder)'),
    );
  }
}

class MrImmoCollectionScreen extends StatelessWidget {
  const MrImmoCollectionScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Mr Immo Collection',
      child: Text('Mr Immo Collection moduleId=$moduleId (placeholder)'),
    );
  }
}

class ServiceModuleScreen extends StatelessWidget {
  const ServiceModuleScreen({super.key, required this.moduleId, this.bundleUrl});
  final String moduleId;
  final String? bundleUrl;

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Service Module',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('moduleId: $moduleId'),
          const SizedBox(height: 8),
          Text('bundleUrl: ${bundleUrl ?? '(none)'}'),
          const SizedBox(height: 16),
          const Text('Next step: load the module bundle (webview or native runtime loader).'),
        ],
      ),
    );
  }
}
*/
