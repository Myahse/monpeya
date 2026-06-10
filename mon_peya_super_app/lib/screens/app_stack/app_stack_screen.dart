import 'package:flutter/material.dart';

import 'app_stack_controller.dart';
import 'app_stack_scope.dart';
import 'app_stack_types.dart';
import '../../widgets/mon_peya_module_gate.dart';
import 'main_tabs_shell.dart';
import 'services/billetterie_screen.dart';
import 'services/mr_immo_screens.dart';
import 'services/service_module_screen.dart';
import 'modules/module_web_view_screen.dart';
import 'widgets/nteri_bubble.dart';

class AppStackScreen extends StatefulWidget {
  const AppStackScreen({super.key});
  static const routeName = '/app';

  @override
  State<AppStackScreen> createState() => _AppStackScreenState();
}

class _AppStackScreenState extends State<AppStackScreen> {
  final _controller = AppStackController();

  /// Keeps module WebViews alive when returning home (scroll, page, form state).
  final Map<String, Widget> _moduleCache = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _moduleCacheKey(AppStackItem item) {
    final moduleKey = item.params['moduleKey'] as String?;
    if (moduleKey != null && moduleKey.isNotEmpty) return moduleKey;
    return '${item.name}-${item.id}';
  }

  String? _activeModuleCacheKey(AppStackState state) {
    final current = state.current;
    if (!AppStackRoute.isModuleRoute(current.name)) return null;
    return _moduleCacheKey(current);
  }

  void _ensureModuleCached(AppStackItem item) {
    final key = _moduleCacheKey(item);
    _moduleCache.putIfAbsent(
      key,
      () => KeyedSubtree(
        key: ValueKey('cached-module-$key'),
        child: _buildModuleScreen(item),
      ),
    );
  }

  Widget _buildModuleScreen(AppStackItem item) {
    final params = item.params;
    return switch (item.name) {
      AppStackRoute.billetterie => const MonPeyaModuleGate(child: BilletterieModuleScreen()),
      AppStackRoute.mrImmoRental => const MonPeyaModuleGate(child: MrImmoRentalScreen()),
      AppStackRoute.mrImmoConstruction => const MonPeyaModuleGate(child: MrImmoConstructionScreen()),
      AppStackRoute.mrImmoCollection => const MonPeyaModuleGate(child: MrImmoCollectionScreen()),
      AppStackRoute.serviceModule => ServiceModuleScreen(
          moduleId: (params['moduleId'] as String?) ?? '',
          bundleUrl: params['bundleUrl'] as String?,
          url: params['url'] as String?,
          title: params['title'] as String?,
        ),
      AppStackRoute.webModule => ModuleWebViewScreen(
          title: (params['title'] as String?) ?? 'Module',
          url: (params['url'] as String?) ?? '',
          moduleId: params['moduleId'] as String?,
          isAssetModule: params['isAssetModule'] as bool? ?? false,
          assetPath: params['assetPath'] as String?,
          partnerId: params['partnerId'] as String?,
          moduleKey: params['moduleKey'] as String?,
        ),
      _ => const SizedBox.shrink(),
    };
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

          if (AppStackRoute.isModuleRoute(activeName)) {
            _ensureModuleCached(active);
          }

          final visibleModuleKey = _activeModuleCacheKey(state);

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
              fit: StackFit.expand,
              children: [
                // Home + tabs stay mounted — preserves scroll, tab, and form state.
                const MainTabsShell(key: MainTabsShell.storageKey),
                for (final entry in _moduleCache.entries)
                  Positioned.fill(
                    child: Offstage(
                      offstage: entry.key != visibleModuleKey,
                      child: TickerMode(
                        enabled: entry.key == visibleModuleKey,
                        child: IgnorePointer(
                          ignoring: entry.key != visibleModuleKey,
                          child: entry.value,
                        ),
                      ),
                    ),
                  ),
                if (AppStackRoute.isModuleRoute(activeName))
                  Positioned.fill(
                    child: NteriBubble(
                      expanded: state.menuVisible,
                      activeRouteName: activeName,
                      currentModuleKey: active.params['moduleKey'] as String?,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/*

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
                _TabNavigator(navigatorKey: _navKeys[MainTab.home]!, root: const HomeScreen()),
                _TabNavigator(navigatorKey: _navKeys[MainTab.peyapay]!, root: const PeyapayScreen()),
                _TabNavigator(
                  navigatorKey: _navKeys[MainTab.subscriptions]!,
                  root: const SubscriptionsScreen(),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom + MainBottomNavigationBar.barHeight,
              child: FloatingActionButton.extended(
                onPressed: () => appStack?.toggleMenu(),
                icon: const Icon(Icons.apps),
                label: const Text('NTERI'),
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (idx) => _selectTab(MainTab.values[idx]),
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

// --- Module screens (placeholders) ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.maybeOf(context);
    return _ModuleScaffold(
      title: 'Home',
      children: [
        const _ModuleHeader(title: 'Mon Peya', subtitle: 'Super app shell (Flutter)'),
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
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'Transfer')),
          ),
        ),
        _ModuleTile(
          icon: Icons.receipt_long_outlined,
          title: 'Transactions',
          subtitle: 'Payment history',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'Transactions')),
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
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'My services')),
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
  const _ModuleScaffold({required this.title, required this.children});
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

// ===== AppStack primitives (Flutter equivalent of RN AppStackContext) =====

class AppStackRoute {
  static const main = 'Main';
  static const billetterie = 'Billetterie';
  static const mrImmoRental = 'MrImmoRental';
  static const mrImmoConstruction = 'MrImmoConstruction';
  static const mrImmoCollection = 'MrImmoCollection';
  static const serviceModule = 'ServiceModule';
}

class AppStackItem {
  AppStackItem({required this.id, required this.name, required this.params});
  final String id;
  final String name;
  final Map<String, Object?> params;
}

class AppStackState {
  const AppStackState({required this.stack, required this.menuVisible});
  final List<AppStackItem> stack;
  final bool menuVisible;

  AppStackItem get current => stack.isNotEmpty
      ? stack.last
      : AppStackItem(id: 'main-0', name: AppStackRoute.main, params: const {});
}

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

class AppStackScope extends InheritedWidget {
  const AppStackScope({required this.controller, required super.child, super.key});
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
      (icon: Icons.home_outlined, label: 'Tableau de bord', onTap: appStack.navigateToMain),
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
        onTap: () => rootNavKey.currentState?.pushNamed(SettingsScreen.routeName),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
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
  const _ServiceScaffold({required this.title, required this.child});
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
          IconButton(icon: const Icon(Icons.apps), onPressed: appStack.toggleMenu),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: child),
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
          const Text('Next step: load the module bundle natively.'),
        ],
      ),
    );
  }
}

*/

