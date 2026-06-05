import 'package:flutter/material.dart';

import 'app_stack_scope.dart';
import 'app_stack_types.dart';

class MonPeyaMyServicesScreen extends StatelessWidget {
  const MonPeyaMyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appStack = AppStackScope.maybeOf(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(999),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.chevron_left, size: 26),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Mon espace personnel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40, height: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(
                    'Mes services',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Services disponibles sur votre compte',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  _ServicesGrid(
                    onOpenBilletterie: () => appStack?.openService(
                      AppStackRoute.billetterie,
                      params: const {'moduleId': 'billetterie-electronique'},
                    ),
                    onOpenRental: () => appStack?.openService(
                      AppStackRoute.mrImmoRental,
                      params: const {'moduleId': 'mr-immo-rental'},
                    ),
                    onOpenConstruction: () => appStack?.openService(
                      AppStackRoute.mrImmoConstruction,
                      params: const {'moduleId': 'mr-immo-construction'},
                    ),
                    onOpenCollection: () => appStack?.openService(
                      AppStackRoute.mrImmoCollection,
                      params: const {'moduleId': 'mr-immo-collection'},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.onOpenBilletterie,
    required this.onOpenRental,
    required this.onOpenConstruction,
    required this.onOpenCollection,
  });

  final VoidCallback onOpenBilletterie;
  final VoidCallback onOpenRental;
  final VoidCallback onOpenConstruction;
  final VoidCallback onOpenCollection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const gap = 12.0;
        final tileW = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final iconSize = tileW < 80 ? 44.0 : 52.0;

        Widget tile({
          required Widget icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return SizedBox(
            width: tileW,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  children: [
                    Container(
                      width: iconSize + 15,
                      height: iconSize + 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: icon),
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: [
            tile(
              icon: const Icon(Icons.confirmation_number_outlined, size: 28),
              label: 'Billetterie',
              onTap: onOpenBilletterie,
            ),
            tile(
              icon: const Icon(Icons.home_work_outlined, size: 28),
              label: 'Mr Immo Rental',
              onTap: onOpenRental,
            ),
            tile(
              icon: const Icon(Icons.construction_outlined, size: 28),
              label: 'Construction',
              onTap: onOpenConstruction,
            ),
            tile(
              icon: const Icon(Icons.collections_bookmark_outlined, size: 28),
              label: 'Collection',
              onTap: onOpenCollection,
            ),
          ],
        );
      },
    );
  }
}

