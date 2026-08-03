import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/event/models/billetterie.event.dart';
import 'package:billetterie/src/features/event/services/billetterie_event_api.service.dart';
import 'package:billetterie/src/features/event/widgets/event_bottom_nav.widget.dart';

/// Organizer / business home — dashboard + event list.
class EventBusinessHomeView extends StatelessWidget {
  const EventBusinessHomeView({
    super.key,
    required this.summary,
    required this.loading,
    required this.onRefresh,
    required this.onCreateEvent,
    required this.onOpenEvent,
    required this.onScanTickets,
    this.onPublishEvent,
    this.error,
  });

  final CreatorDashboardSummary? summary;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreateEvent;
  final ValueChanged<BilletterieEvent> onOpenEvent;
  final VoidCallback onScanTickets;
  final Future<void> Function(BilletterieEvent event)? onPublishEvent;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final textTheme = Theme.of(context).textTheme;
    final events = summary?.events ?? const <BilletterieEvent>[];
    final bottomPad = BilletterieEventBottomNav.contentBottomPadding(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Espace organisateur',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: brand.text,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              color: brand.primaryDark,
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 8),
                children: [
                  if (error != null) ...[
                    _ErrorBanner(brand: brand, message: error!),
                    const SizedBox(height: 12),
                  ],
                  if (loading && summary == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _EarningsCard(
                      brand: brand,
                      revenue: summary?.totalRevenue ?? 0,
                      currency: summary?.currency ?? 'FCFA',
                      generated: summary?.totalTicketsGenerated ?? 0,
                      sold: summary?.totalTicketsSold ?? 0,
                      consumed: summary?.totalTicketsConsumed ?? 0,
                      eventCount: events.length,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onCreateEvent,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Créer un événement'),
                            style: FilledButton.styleFrom(
                              backgroundColor: brand.primaryDark,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: onScanTickets,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brand.primaryDark,
                            side: BorderSide(color: brand.primaryDark),
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Mes événements',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: brand.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (events.isEmpty)
                      _EmptyEvents(brand: brand, onCreate: onCreateEvent)
                    else
                      ...events.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EventBusinessTile(
                            brand: brand,
                            event: e,
                            currency: summary?.currency ?? 'FCFA',
                            onTap: () => onOpenEvent(e),
                            onPublish: e.isDraft && onPublishEvent != null
                                ? () => onPublishEvent!(e)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.brand,
    required this.revenue,
    required this.currency,
    required this.generated,
    required this.sold,
    required this.consumed,
    required this.eventCount,
  });

  final BilletterieBrand brand;
  final int revenue;
  final String currency;
  final int generated;
  final int sold;
  final int consumed;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Argent encaissé',
            style: textTheme.labelLarge?.copyWith(
              color: brand.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatMoney(revenue)} $currency',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: brand.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(brand: brand, label: 'Événements', value: '$eventCount'),
              const SizedBox(width: 8),
              _StatChip(brand: brand, label: 'Générés', value: '$generated'),
              const SizedBox(width: 8),
              _StatChip(brand: brand, label: 'Vendus', value: '$sold'),
              const SizedBox(width: 8),
              _StatChip(brand: brand, label: 'Scannés', value: '$consumed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.brand,
    required this.label,
    required this.value,
  });

  final BilletterieBrand brand;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: brand.text,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: brand.muted,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventBusinessTile extends StatelessWidget {
  const _EventBusinessTile({
    required this.brand,
    required this.event,
    required this.onTap,
    required this.currency,
    this.onPublish,
  });

  final BilletterieBrand brand;
  final BilletterieEvent event;
  final VoidCallback onTap;
  final String currency;
  final Future<void> Function()? onPublish;

  @override
  Widget build(BuildContext context) {
    final status = event.statusLabelFr;
    final sold = event.ticketsSold ?? 0;
    final cap = event.expectedAttendees;
    final earned = event.revenueEarned;

    return Material(
      color: brand.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brand.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: brand.primaryDark.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.celebration_outlined,
                      color: brand.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: brand.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (event.date.isNotEmpty) event.date,
                            if (event.venue.isNotEmpty) event.venue,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: brand.muted,
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cap != null ? '$sold / $cap billets' : '$sold vendus',
                          style: TextStyle(
                            color: brand.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.isDraft
                          ? brand.muted.withValues(alpha: 0.15)
                          : brand.primarySoft.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: event.isDraft ? brand.muted : brand.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              if (earned > 0 || sold > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: brand.primarySoft.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: brand.primaryDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recettes',
                          style: TextStyle(
                            color: brand.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatMoney(earned)} $currency',
                        style: TextStyle(
                          color: brand.primaryDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onPublish != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: () => onPublish!(),
                    icon: const Icon(Icons.publish_rounded, size: 18),
                    label: const Text(
                      'Publier',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: brand.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMoney(int value) {
  final raw = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final fromEnd = raw.length - i;
    buf.write(raw[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(' ');
  }
  return buf.toString();
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents({required this.brand, required this.onCreate});

  final BilletterieBrand brand;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: brand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        children: [
          Icon(Icons.event_note_outlined, size: 40, color: brand.muted),
          const SizedBox(height: 10),
          Text(
            'Aucun événement pour le moment',
            style: TextStyle(
              color: brand.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Créez votre premier événement pour commencer à vendre des billets.',
            textAlign: TextAlign.center,
            style: TextStyle(color: brand.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onCreate,
            child: Text(
              'Créer maintenant',
              style: TextStyle(
                color: brand.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.brand, required this.message});

  final BilletterieBrand brand;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brand.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: brand.danger,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
