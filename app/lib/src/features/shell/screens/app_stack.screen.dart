import 'package:flutter/material.dart';

import 'package:app/src/features/shell/controllers/app_stack.controller.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';
import 'package:app/src/features/shell/widgets/mon_peya_module_gate.widget.dart';
import 'package:app/src/features/shell/widgets/main_tabs.shell.dart';
import 'package:app/src/features/shell/services/screens/billetterie.screen.dart';
import 'package:app/src/features/shell/services/screens/leadway_assurance.screen.dart';
import 'package:app/src/features/shell/services/screens/grenier.screen.dart';
import 'package:app/src/features/shell/services/mr_immo.screens.dart';
import 'package:app/src/features/shell/services/screens/service_module.screen.dart';
import 'package:app/src/features/shell/modules/screens/module_web_view.screen.dart';
import 'package:app/src/features/shell/widgets/nteri_bubble.widget.dart';

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
      AppStackRoute.billetterieTransport =>
        const MonPeyaModuleGate(child: BilletterieTransportModuleScreen()),
      AppStackRoute.billetterieEvent =>
        const MonPeyaModuleGate(child: BilletterieEventModuleScreen()),
      AppStackRoute.leadwayAssurance => const MonPeyaModuleGate(child: LeadwayModuleScreen()),
      AppStackRoute.mrImmoRental => const MonPeyaModuleGate(child: MrImmoRentalScreen()),
      AppStackRoute.mrImmoConstruction => const MonPeyaModuleGate(child: MrImmoConstructionScreen()),
      AppStackRoute.mrImmoCollection => const MonPeyaModuleGate(child: MrImmoCollectionScreen()),
      AppStackRoute.monGrenier =>
        const MonPeyaModuleGate(child: MonGrenierModuleScreen()),
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
              _controller.handleSystemBack();
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

