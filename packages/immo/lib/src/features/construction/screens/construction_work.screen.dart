import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// "Commandes" (supplier) or "Chantiers" (site manager) tab.
class ConstructionWorkScreen extends StatelessWidget {
  const ConstructionWorkScreen({super.key, required this.role});

  final ConstructionRole role;

  @override
  Widget build(BuildContext context) {
    final supplier = role == ConstructionRole.supplier;
    return ImmoTabPage(
      key: ValueKey(role),
      title: supplier ? 'Commandes' : 'Chantiers',
      subtitle: supplier
          ? 'Commandes reçues et livraisons'
          : 'Suivi de vos chantiers',
      children: [
        ImmoStatRow(
          stats: supplier
              ? const [
                  ImmoStat(label: 'À préparer', value: '0', icon: Icons.pending_actions_rounded),
                  ImmoStat(label: 'En livraison', value: '0', icon: Icons.local_shipping_outlined),
                  ImmoStat(label: 'Livrées', value: '0', icon: Icons.task_alt_rounded),
                ]
              : const [
                  ImmoStat(label: 'En cours', value: '0', icon: Icons.timelapse_rounded),
                  ImmoStat(label: 'En pause', value: '0', icon: Icons.pause_circle_outline),
                  ImmoStat(label: 'Terminés', value: '0', icon: Icons.task_alt_rounded),
                ],
        ),
        const SizedBox(height: ImmoSpacing.lg),
        ImmoSectionTitle(supplier ? 'Commandes récentes' : 'Mes chantiers'),
        ImmoEmptyState(
          icon: supplier ? Icons.inventory_2_outlined : Icons.foundation_rounded,
          title: supplier ? 'Aucune commande' : 'Aucun chantier',
          message: supplier
              ? 'Les commandes des chefs de chantier s’afficheront ici dès réception.'
              : 'Ajoutez un chantier pour suivre l’avancement, l’équipe et les achats.',
        ),
      ],
    );
  }
}
