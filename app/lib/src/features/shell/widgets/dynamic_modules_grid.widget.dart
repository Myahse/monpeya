import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/widgets/module.icon.dart';
import 'package:app/src/features/shell/widgets/vertical_service_tile.widget.dart';

class DynamicModulesGrid extends StatelessWidget {
  const DynamicModulesGrid({
    super.key,
    required this.modules,
    required this.onOpenModule,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onOpenModule;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return const _EmptyModulesHint();
    }

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 4;
          const gap = 12.0;
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final tileW = (maxWidth - gap * (columns - 1)) / columns;
          final iconSize = tileW < 80 ? 44.0 : 52.0;

          return Wrap(
            spacing: gap,
            runSpacing: 14,
            children: [
              for (final module in modules)
                _ModuleTile(
                  module: module,
                  label: module.name,
                  isPartner: module.isPartnerModule,
                  iconBoxSize: iconSize,
                  tileWidth: tileW.clamp(56.0, 120.0),
                  onTap: () => onOpenModule(module),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.label,
    required this.iconBoxSize,
    required this.tileWidth,
    required this.onTap,
    this.isPartner = false,
  });

  final AppModule module;
  final String label;
  final double iconBoxSize;
  final double tileWidth;
  final VoidCallback onTap;
  final bool isPartner;

  @override
  Widget build(BuildContext context) {
    final immoBranded = isImmoBrandedModuleIcon(
      moduleKey: module.moduleKey,
      iconKey: module.icon,
    );
    final iconSize = immoBranded ? iconBoxSize * 0.72 : iconBoxSize * 0.48;

    return VerticalServiceTile(
      width: tileWidth,
      label: label,
      showPartnerDot: isPartner,
      onTap: onTap,
      icon: ModuleIcon.forModule(module, size: iconSize),
    );
  }
}

class _EmptyModulesHint extends StatelessWidget {
  const _EmptyModulesHint();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Aucun service disponible pour le moment.',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }
}
