import 'package:flutter/material.dart';

import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// Payments tab shared by both roles.
class ConstructionPaymentsView extends StatelessWidget {
  const ConstructionPaymentsView({super.key, required this.incoming});

  /// Supplier receives payments; site manager sends them.
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    return ImmoTabPage(
      title: 'Paiements',
      subtitle: incoming ? 'Vos encaissements' : 'Vos règlements fournisseurs',
      children: [
        ImmoStatRow(
          stats: [
            ImmoStat(
              label: incoming ? 'Encaissé ce mois' : 'Payé ce mois',
              value: '0 F',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const ImmoStat(
              label: 'En attente',
              value: '0 F',
              icon: Icons.schedule_rounded,
            ),
          ],
        ),
        const SizedBox(height: ImmoSpacing.lg),
        const ImmoSectionTitle('Historique'),
        ImmoEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Aucun paiement',
          message: incoming
              ? 'Les règlements reçus via Peya Pay apparaîtront ici.'
              : 'Vos paiements aux fournisseurs via Peya Pay apparaîtront ici.',
        ),
      ],
    );
  }
}
