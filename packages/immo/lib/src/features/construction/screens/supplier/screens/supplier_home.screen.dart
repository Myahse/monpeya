import 'package:flutter/material.dart';

import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/construction_home_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({
    super.key,
    required this.store,
    this.onRoleChanged,
    required this.onOpenTab,
  });

  final ConstructionStore store;
  final ValueChanged<ConstructionRole>? onRoleChanged;
  final ValueChanged<ConstructionTab> onOpenTab;

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.store.supplierOrders == null) widget.store.loadSupplierOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => _layout(),
    );
  }

  Widget _layout() {
    final orders = widget.store.supplierOrders ?? const [];
    final now = DateTime.now();
    final thisMonth = orders
        .where((o) => o.isDelivered && o.deliveredAt != null && o.deliveredAt!.month == now.month && o.deliveredAt!.year == now.year)
        .fold<double>(0, (s, o) => s + (o.total ?? 0));
    return ConstructionHomeLayout(
      role: ConstructionRole.supplier,
      onRoleChanged: widget.onRoleChanged,
      stats: [
        ImmoStat(
          label: 'À livrer',
          value: '${orders.where((o) => o.isToDeliver).length}',
          icon: Icons.local_shipping_outlined,
        ),
        ImmoStat(
          label: 'Livrées',
          value: '${orders.where((o) => o.isDelivered).length}',
          icon: Icons.task_alt_rounded,
        ),
        ImmoStat(label: 'Ce mois', value: formatFcfaCompact(thisMonth), icon: Icons.trending_up_rounded),
      ],
      actions: [
        ImmoAction(
          title: 'Commandes',
          subtitle: 'Suivre les commandes reçues',
          icon: Icons.inventory_2_rounded,
          onTap: () => widget.onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Livraisons',
          subtitle: 'Confirmer à la livraison',
          icon: Icons.local_shipping_rounded,
          onTap: () => widget.onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Paiements',
          subtitle: 'Encaissements Peya Pay',
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => widget.onOpenTab(ConstructionTab.payments),
        ),
        ImmoAction(
          title: 'Messages',
          subtitle: 'Échanger avec les chantiers',
          icon: Icons.chat_bubble_rounded,
          onTap: () => widget.onOpenTab(ConstructionTab.messages),
        ),
      ],
      emptyTitle: 'Aucune activité pour le moment',
      emptyMessage: 'Vos nouvelles commandes et livraisons apparaîtront ici.',
    );
  }
}
