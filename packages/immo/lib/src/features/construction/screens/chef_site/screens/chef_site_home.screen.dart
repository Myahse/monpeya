import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/widgets/construction_home_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class ChefSiteHomeScreen extends StatelessWidget {
  const ChefSiteHomeScreen({
    super.key,
    required this.onRoleChanged,
    required this.onOpenTab,
  });

  final ValueChanged<ConstructionRole> onRoleChanged;
  final ValueChanged<ConstructionTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ConstructionHomeLayout(
      role: ConstructionRole.chefSite,
      onRoleChanged: onRoleChanged,
      stats: const [
        ImmoStat(label: 'Chantiers actifs', value: '0', icon: Icons.foundation_rounded),
        ImmoStat(label: 'Demandes en cours', value: '0', icon: Icons.assignment_outlined),
        ImmoStat(label: 'Équipe', value: '0', icon: Icons.groups_outlined),
      ],
      actions: [
        ImmoAction(
          title: 'Chantiers',
          subtitle: 'Avancement et budget',
          icon: Icons.foundation_rounded,
          onTap: () => onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Demandes',
          subtitle: 'Matériaux et fournisseurs',
          icon: Icons.assignment_rounded,
          onTap: () => onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Paiements',
          subtitle: 'Régler les fournisseurs',
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => onOpenTab(ConstructionTab.payments),
        ),
        ImmoAction(
          title: 'Messages',
          subtitle: 'Équipe et fournisseurs',
          icon: Icons.chat_bubble_rounded,
          onTap: () => onOpenTab(ConstructionTab.messages),
        ),
      ],
      emptyTitle: 'Aucun chantier suivi',
      emptyMessage: 'Créez ou rejoignez un chantier pour suivre son avancement ici.',
    );
  }
}
