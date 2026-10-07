import 'package:flutter/material.dart';

import 'package:sim/src/data/models/sim_assurance_card.model.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';
import 'package:sim/src/presentation/widgets/sim_assurance_card_flip.widget.dart';
import 'package:sim/src/presentation/widgets/sim_shared_widgets.dart';

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
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: SimBrand.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: SimBrand.primary,
            padding: EdgeInsets.fromLTRB(8, top + 4, 20, 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Retour',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: SimRise(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SimBrand.title.toUpperCase(),
                          style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .6),
                        ),
                        const SizedBox(height: 4),
                        const Text('Mes cartes', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                        Text(
                          '${cards.length} carte${cards.length > 1 ? 's' : ''} · prise en charge et validité',
                          style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SimSheet(
              child: cards.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune carte enregistrée pour le moment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: SimBrand.muted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
                      itemCount: cards.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return SimRise(
                          delay: Duration(milliseconds: 80 * index),
                          child: _SavedCardTile(
                            record: card,
                            onTap: onOpenCard == null ? null : () => onOpenCard!(card),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SimBottomBar(label: 'Nouvelle souscription', onPrimary: onNewSubscription),
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
