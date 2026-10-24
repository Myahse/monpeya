import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/construction_home_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class MoyensGenerauxHomeScreen extends StatelessWidget {
  const MoyensGenerauxHomeScreen({
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
    final requests = store.requests.where((r) => r.isMaterial).toList();
    return ConstructionHomeLayout(
      role: ConstructionRole.moyensGeneraux,
      onRoleChanged: onRoleChanged,
      stats: [
        ImmoStat(
          label: 'À commander',
          value: '${requests.where((r) => r.isToOrder).length}',
          icon: Icons.shopping_cart_outlined,
        ),
        ImmoStat(
          label: 'Commandées',
          value: '${requests.where((r) => r.isOrdered).length}',
          icon: Icons.local_shipping_outlined,
        ),
        ImmoStat(
          label: 'Livrées',
          value: '${requests.where((r) => r.isDelivered).length}',
          icon: Icons.task_alt_rounded,
        ),
      ],
      actions: [
        ImmoAction(
          title: 'Achats',
          subtitle: 'Commander aux fournisseurs',
          icon: Icons.shopping_cart_rounded,
          onTap: () => onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Messages',
          subtitle: 'Chantiers et fournisseurs',
          icon: Icons.chat_bubble_rounded,
          onTap: () => onOpenTab(ConstructionTab.messages),
        ),
      ],
      emptyTitle: 'Aucune activité pour le moment',
      emptyMessage: 'Les commandes passées aux fournisseurs apparaîtront ici.',
    );
  }
}
