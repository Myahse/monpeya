import 'package:flutter/material.dart';

import 'package:sim/src/data/models/sim_assurance_card.model.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';
import 'package:sim/src/presentation/widgets/sim_assurance_card_flip.widget.dart';

class SimMyCardsView extends StatelessWidget {
  const SimMyCardsView({
    super.key,
    required this.cards,
    required this.onBack,
    required this.onNewSubscription,
    this.onOpenCard,
  });

  final List<SimAssuranceCardRecord> cards;
  final VoidCallback onBack;
  final VoidCallback onNewSubscription;
  final ValueChanged<SimAssuranceCardRecord>? onOpenCard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(tooltip: 'Retour', onPressed: onBack, icon: const Icon(Icons.chevron_left)),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes cartes SIM',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: SimBrand.textDark),
                        ),
                        Text(
                          'Prise en charge · validité',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SimBrand.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucune carte enregistrée pour le moment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return _SavedCardTile(
                          record: card,
                          onTap: onOpenCard == null ? null : () => onOpenCard!(card),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: SimBrand.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onNewSubscription,
                child: const Text('Nouvelle souscription', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({required this.record, this.onTap});

  final SimAssuranceCardRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = record.isActive ? SimBrand.primary : Colors.grey.shade600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimAssuranceCardFlip(record: record, compact: true, frozen: !record.isActive),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.validityLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SimBrand.textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    record.statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
