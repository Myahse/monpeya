import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/construction_home_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class SuperviseurHomeScreen extends StatelessWidget {
  const SuperviseurHomeScreen({
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
    final requests = store.requests;
    return ConstructionHomeLayout(
      role: ConstructionRole.superviseur,
      onRoleChanged: onRoleChanged,
      stats: [
        ImmoStat(
          label: 'À valider',
          value: '${requests.where((r) => r.isPending).length}',
          icon: Icons.pending_actions_rounded,
        ),
        ImmoStat(
          label: 'Validées',
          value: '${requests.where((r) => !r.isPending && !r.isRefused).length}',
          icon: Icons.task_alt_rounded,
        ),
        ImmoStat(
          label: 'Refusées',
          value: '${requests.where((r) => r.isRefused).length}',
          icon: Icons.block_rounded,
        ),
      ],
      actions: [
        ImmoAction(
          title: 'Demandes',
          subtitle: 'Valider ou refuser',
          icon: Icons.fact_check_rounded,
          onTap: () => onOpenTab(ConstructionTab.work),
        ),
        ImmoAction(
          title: 'Messages',
          subtitle: 'Chefs de chantier',
          icon: Icons.chat_bubble_rounded,
          onTap: () => onOpenTab(ConstructionTab.messages),
        ),
      ],
      emptyTitle: 'Aucune activité pour le moment',
      emptyMessage: 'Les demandes validées ou refusées apparaîtront ici.',
    );
  }
}
