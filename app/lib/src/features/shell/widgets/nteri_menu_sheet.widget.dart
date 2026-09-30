import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/widgets/module.icon.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/features/settings/presentation/screens/settings.screen.dart';
import 'package:app/src/features/shell/widgets/mon_peya_module_gate.widget.dart';
import 'package:app/src/features/shell/widgets/vertical_service_tile.widget.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';

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
  List<AppModule> get _modules => ModuleRepository.modules;

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
              child: Builder(
                builder: (context) {
                  final modules = _modules;

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
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                          children: [
                            for (final module in modules)
                              _ModuleMenuTile(
                                module: module,
                                label: module.name,
                                selected: module.moduleKey == widget.currentModuleKey,
                                onTap: () => _closeAnd(
                                  () => openModuleIfRegistered(context, module),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSide = constraints.maxWidth;
        final hasLogo = moduleIconAsset(
              moduleKey: module.moduleKey,
              iconKey: module.icon,
            ) !=
            null;
        final iconSize = hasLogo
            ? (tileSide - 8).clamp(28.0, 40.0)
            : (tileSide * 0.52).clamp(22.0, 30.0);

        return VerticalServiceTile(
          width: tileSide,
          label: label,
          selected: selected,
          showLabel: false,
          onTap: onTap,
          icon: ModuleIcon.forModule(
            module,
            size: iconSize,
            color: selected ? cs.primary : cs.onSurface,
          ),
        );
      },
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
