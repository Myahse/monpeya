import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// Construction home — Location layout (accent header + sheet) in orange,
/// with the role switch on the header.
class ConstructionHomeLayout extends StatelessWidget {
  const ConstructionHomeLayout({
    super.key,
    required this.role,
    required this.onRoleChanged,
    required this.stats,
    required this.actions,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final ConstructionRole role;
  final ValueChanged<ConstructionRole> onRoleChanged;
  final List<ImmoStat> stats;
  final List<ImmoAction> actions;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    final name = (session.displayName ?? '').trim();

    return ImmoHeaderPage(
      eyebrow: 'Mr Immo Construction',
      title: name.isEmpty ? 'Bonjour 👋' : 'Bonjour, $name',
      subtitle: role == ConstructionRole.supplier
          ? 'Vos commandes et livraisons'
          : 'Vos chantiers en un coup d’œil',
      trailing: const Icon(Icons.construction_rounded,
          color: Colors.white, size: 30),
      headerExtra: ImmoHeaderSegment(
        labels: [for (final r in ConstructionRole.values) r.label],
        selected: role.index,
        onChanged: (i) => onRoleChanged(ConstructionRole.values[i]),
      ),
      body: ListView(
        key: ValueKey(role),
        padding: EdgeInsets.fromLTRB(
          ImmoSpacing.lg,
          ImmoSpacing.lg,
          ImmoSpacing.lg,
          ImmoPillNavBar.contentBottomPadding(context),
        ),
        children: ImmoStagger.wrap([
          ImmoStatRow(stats: stats),
          const SizedBox(height: ImmoSpacing.lg),
          const ImmoSectionTitle('Actions rapides'),
          ImmoActionGrid(actions: actions),
          const SizedBox(height: ImmoSpacing.lg),
          const ImmoSectionTitle('Activité récente'),
          ImmoEmptyState(
            icon: Icons.history_rounded,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ]),
      ),
    );
  }
}
