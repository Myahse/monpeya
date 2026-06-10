import 'package:flutter/material.dart';

import '../../../app/modules/app_module.dart';
import '../../../app/modules/module_icon.dart';
import '../../../app/modules/module_repository.dart';
import '../../../app/routing/routes.dart';
import '../../settings/settings_screen.dart';
import '../../../widgets/mon_peya_module_gate.dart';
import '../app_stack_scope.dart';
import '../app_stack_types.dart';

/// Expandable menu panel content (home, modules, settings).
class NteriMenuPanel extends StatefulWidget {
  const NteriMenuPanel({
    super.key,
    required this.activeRouteName,
    this.currentModuleKey,
    this.maxHeight,
    this.compactHeader = false,
  });

  final String activeRouteName;
  final String? currentModuleKey;
  final double? maxHeight;
  final bool compactHeader;

  @override
  State<NteriMenuPanel> createState() => _NteriMenuPanelState();
}

class _NteriMenuPanelState extends State<NteriMenuPanel> {
  final _repository = ModuleRepository();
  late Future<ModuleFetchResult> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _repository.fetchModulesResult();
  }

  void _closeAnd(VoidCallback action) {
    final appStack = AppStackScope.of(context);
    if (appStack.value.menuVisible) {
      appStack.toggleMenu();
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final maxH = widget.maxHeight ?? MediaQuery.sizeOf(context).height * 0.52;

    return Material(
      elevation: 14,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.compactHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: appStack.canGoBack ? () => _closeAnd(appStack.goBack) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const Expanded(
                    child: Text(
                      "N'TERI",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: appStack.toggleMenu,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: FutureBuilder<ModuleFetchResult>(
                future: _modulesFuture,
                builder: (context, snapshot) {
                  final loading = snapshot.connectionState != ConnectionState.done;
                  final modules = snapshot.data?.modules ?? const <AppModule>[];

                  if (loading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HomeTile(
                        selected: widget.activeRouteName == AppStackRoute.main,
                        onTap: () => _closeAnd(appStack.popToHome),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Mes services',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (modules.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Aucun service disponible',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                          ),
                        )
                      else
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 0.92,
                          children: [
                            for (final module in modules)
                              _ModuleMenuTile(
                                module: module,
                                label: module.name,
                                selected: module.moduleKey == widget.currentModuleKey,
                                onTap: () => _closeAnd(
                                  () => openModuleIfRegistered(context, () => appStack.openModule(module)),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      _SettingsTile(
                        onTap: () => _closeAnd(
                          () => rootNavKey.currentState?.pushNamed(SettingsScreen.routeName),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet variant (e.g. service scaffold app bar).
class NteriMenuSheet extends StatelessWidget {
  const NteriMenuSheet({
    super.key,
    required this.activeRouteName,
    this.currentModuleKey,
  });

  final String activeRouteName;
  final String? currentModuleKey;

  @override
  Widget build(BuildContext context) {
    return NteriMenuPanel(
      activeRouteName: activeRouteName,
      currentModuleKey: currentModuleKey,
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.onTap, this.selected = false});

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.home_rounded, color: cs.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Accueil Mon Peya',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleMenuTile extends StatelessWidget {
  const _ModuleMenuTile({
    required this.module,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final AppModule module;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : null,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: cs.primary, width: 1.5) : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ModuleIcon.forModule(
              module,
              size: 32,
              color: selected ? cs.primary : cs.onSurface,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.settings_outlined, size: 22, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(
              'Paramètres',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
