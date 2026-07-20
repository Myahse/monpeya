import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/features/transport/services/conductor_ticket.store.dart';
import 'package:billetterie/src/shared/widgets/billetterie_bottom_nav.widget.dart';

/// Business / conductor home: earnings + generated tickets + sales.
class BusinessHomeView extends StatelessWidget {
  const BusinessHomeView({
    super.key,
    required this.summary,
    required this.generated,
    required this.sales,
    required this.onRefresh,
    required this.onGenerate,
    required this.onOpenTicket,
  });

  final ConductorEarningsSummary summary;
  final List<BilletterieTransportTicket> generated;
  final List<BilletterieTransportTicket> sales;
  final Future<void> Function() onRefresh;
  final VoidCallback onGenerate;
  final void Function(BilletterieTransportTicket ticket) onOpenTicket;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Espace conducteur',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: brand.text,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _EarningsCard(summary: summary),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Générer un billet'),
              style: FilledButton.styleFrom(
                backgroundColor: brand.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            labelColor: brand.text,
            unselectedLabelColor: brand.muted,
            indicatorColor: brand.primaryDark,
            tabs: const [
              Tab(text: 'Mes trajets'),
              Tab(text: 'Ventes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TicketListPane(
                  emptyLabel: 'Aucun billet généré',
                  tickets: generated,
                  onRefresh: onRefresh,
                  onOpenTicket: onOpenTicket,
                  showBuyer: false,
                ),
                _TicketListPane(
                  emptyLabel: 'Aucune vente pour le moment',
                  tickets: sales,
                  onRefresh: onRefresh,
                  onOpenTicket: onOpenTicket,
                  showBuyer: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.summary});

  final ConductorEarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Argent encaissé',
            style: textTheme.labelLarge?.copyWith(color: brand.muted),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.totalEarned} ${summary.currency}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: brand.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(label: 'Générés', value: '${summary.generatedCount}'),
              const SizedBox(width: 8),
              _StatChip(label: 'En vente', value: '${summary.forSaleCount}'),
              const SizedBox(width: 8),
              _StatChip(label: 'Vendus', value: '${summary.soldCount}'),
              const SizedBox(width: 8),
              _StatChip(label: 'Validés', value: '${summary.consumedCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: brand.primarySoft.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: brand.text,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: brand.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketListPane extends StatelessWidget {
  const _TicketListPane({
    required this.emptyLabel,
    required this.tickets,
    required this.onRefresh,
    required this.onOpenTicket,
    required this.showBuyer,
  });

  final String emptyLabel;
  final List<BilletterieTransportTicket> tickets;
  final Future<void> Function() onRefresh;
  final void Function(BilletterieTransportTicket ticket) onOpenTicket;
  final bool showBuyer;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);

    if (tickets.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: brand.muted,
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          BilletterieBottomNav.contentBottomPadding(context),
        ),
        itemCount: tickets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final t = tickets[index];
          return Material(
            color: brand.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onOpenTicket(t),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: brand.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.fromCity} → ${t.toCity}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: brand.text,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (t.ticketCode != null) t.ticketCode!,
                              if (t.status != null) t.status!,
                              '${t.price} ${t.currency}',
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: brand.muted,
                                ),
                          ),
                          if (showBuyer && t.buyerName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Acheteur : ${t.buyerName}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: brand.text,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: brand.muted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
