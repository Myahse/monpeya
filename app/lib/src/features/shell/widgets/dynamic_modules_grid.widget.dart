import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/widgets/module.icon.dart';
import 'package:app/src/core/modules/mergers/module.merger.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';

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

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const gap = 12.0;
        final tileW = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final iconSize = tileW < 80 ? 44.0 : 52.0;

        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: [
            for (final module in modules)
              SizedBox(
                width: tileW,
                child: _ModuleTile(
                  module: module,
                  label: module.name,
                  isPartner: module.isPartnerModule,
                  iconBoxSize: iconSize,
                  onTap: () => onOpenModule(module),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.label,
    required this.iconBoxSize,
    required this.onTap,
    this.isPartner = false,
  });

  final AppModule module;
  final String label;
  final double iconBoxSize;
  final VoidCallback onTap;
  final bool isPartner;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: iconBoxSize + 15,
                  height: iconBoxSize + 8,
                  decoration: BoxDecoration(
                    color: cs.brightness == Brightness.dark
                        ? cs.surfaceContainerHighest
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: ModuleIcon.forModule(
                      module,
                      size: iconBoxSize * 0.55,
                    ),
                  ),
                ),
                if (isPartner)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyModulesHint extends StatelessWidget {
  const _EmptyModulesHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Aucun service disponible pour le moment.',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}

class ModulesLoadingGrid extends StatelessWidget {
  const ModulesLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const gap = 12.0;
        final tileW = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: List.generate(
            4,
            (_) => SizedBox(
              width: tileW,
              child: Column(
                children: [
                  Container(
                    width: 67,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: tileW * 0.7,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ModulesStatusBanner extends StatelessWidget {
  const ModulesStatusBanner({
    super.key,
    required this.result,
    required this.onRetry,
  });

  final ModuleFetchResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = _messageFor(result);
    if (message == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
        if (!result.apiReachable)
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    );
  }

  String? _messageFor(ModuleFetchResult result) {
    if (result.usedBundledFallback && result.loadMode != ModuleLoadMode.bundledOnly) {
      return 'API hors ligne — modules intégrés affichés';
    }
    if (result.loadMode == ModuleLoadMode.bundledOnly) {
      return 'Mode développement — modules intégrés';
    }
    if (result.stats.partnerCount > 0) {
      return '${result.stats.partnerCount} module(s) partenaire via API';
    }
    return null;
  }
}

class ModulesErrorBanner extends StatelessWidget {
  const ModulesErrorBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ModulesStatusBanner(
      result: ModuleFetchResult(
        modules: const [],
        loadMode: ModuleLoadMode.hybrid,
        apiReachable: false,
        usedBundledFallback: true,
        stats: const ModuleFetchStats(
          remoteCount: 0,
          bundledCount: 0,
          partnerCount: 0,
          platformCount: 0,
        ),
      ),
      onRetry: onRetry,
    );
  }
}
