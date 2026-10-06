import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/widgets/construction_home_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class SupplierHomeScreen extends StatelessWidget {
  const SupplierHomeScreen({
    super.key,
    required this.onRoleChanged,
    required this.onOpenTab,
  });

  final ValueChanged<ConstructionRole> onRoleChanged;
  final ValueChanged<ConstructionTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ConstructionHomeLayout(
      role: ConstructionRole.supplier,
      onRoleChanged: onRoleChanged,
      stats: const [
        ImmoStat(label: 'Commandes actives', value: '0', icon: Icons.inventory_2_outlined),
        ImmoStat(label: 'Livraisons en attente', value: '0', icon: Icons.local_shipping_outlined),
        ImmoStat(label: 'Ce mois', value: '0 F', icon: Icons.trending_up_rounded),
      ],
      actions: [
        ImmoAction(
          title: 'Commandes',
          subtitle: 'Suivre les commandes reçues',
          icon: Icons.inventory_2_rounded,
          onTap: () => onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Livraisons',
          subtitle: 'Planifier et confirmer',
          icon: Icons.local_shipping_rounded,
          onTap: () => onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Paiements',
          subtitle: 'Encaissements Peya Pay',
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => onOpenTab(ConstructionTab.payments),
        ),
        ImmoAction(
          title: 'Messages',
          subtitle: 'Échanger avec les chantiers',
          icon: Icons.chat_bubble_rounded,
          onTap: () => onOpenTab(ConstructionTab.messages),
        ),
      ],
      emptyTitle: 'Aucune activité pour le moment',
      emptyMessage: 'Vos nouvelles commandes et livraisons apparaîtront ici.',
    );
  }
}
