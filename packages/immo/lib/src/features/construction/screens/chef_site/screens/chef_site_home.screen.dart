import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/construction_home_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class ChefSiteHomeScreen extends StatelessWidget {
  const ChefSiteHomeScreen({
    super.key,
    required this.store,
    this.onRoleChanged,
    required this.onOpenTab,
  });

  final ConstructionStore store;
  final ValueChanged<ConstructionRole>? onRoleChanged;
  final ValueChanged<ConstructionTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _layout(),
    );
  }

  Widget _layout() {
    final sites = store.sites;
    return ConstructionHomeLayout(
      role: ConstructionRole.chefSite,
      onRoleChanged: onRoleChanged,
      stats: [
        ImmoStat(
          label: 'Chantiers actifs',
          value: '${sites.where((s) => s.active).length}',
          icon: Icons.foundation_rounded,
        ),
        ImmoStat(
          label: 'Demandes en cours',
          value: '${store.requests.where((r) => r.isOpen).length}',
          icon: Icons.assignment_outlined,
        ),
        ImmoStat(
          label: 'En location',
          value: '${sites.where((s) => s.handedOver).length}',
          icon: Icons.key_rounded,
        ),
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
