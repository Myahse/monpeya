import 'package:flutter/material.dart';

import 'package:billetterie/src/presentation/constants/billetterie.brand.dart';
import 'package:billetterie/src/data/datasources/mock.events.dart';
import 'package:billetterie/src/data/models/billetterie.event.dart';
import 'package:billetterie/src/data/models/billetterie.ticket.dart';
import 'package:billetterie/src/presentation/navigation/billetterie_main.navigation.dart';
import 'package:billetterie/src/data/services/billetterie_api.service.dart';
import 'package:billetterie/src/data/services/billetterie_host.payment.dart';
import 'package:billetterie/src/data/services/ticket_storage.service.dart';

const _descriptionMaxLength = 220;

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.onBack,
    required this.onPurchased,
  });

  final String eventId;
  final VoidCallback onBack;
  final ValueChanged<OrderSuccessArgs> onPurchased;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _api = BilletterieApiService();
  final _storage = TicketStorageService();
  BilletterieEvent? _event;
  TicketCategory? _selected;
  bool _fetchComplete = false;
  bool _paying = false;
  bool _favorite = false;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _event = mockBilletterieEvents.cast<BilletterieEvent?>().firstWhere(
          (e) => e?.id == widget.eventId,
          orElse: () => null,
        );
    if (_event?.ticketCategories.isNotEmpty == true) {
      _selected = _event!.ticketCategories.first;
    }
    _load();
  }

  Future<void> _load() async {
    final event = await _api.getEvent(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = event;
      _selected = event?.ticketCategories.isNotEmpty == true ? event!.ticketCategories.first : _selected;
      _fetchComplete = true;
    });
  }

  Future<void> _pay() async {
    final event = _event;
    final cat = _selected;
    if (event == null || cat == null || _paying) return;

    setState(() => _paying = true);
    try {
      if (cat.price > 0) {
        final ok = await BilletterieHostPayment.requestPayment(
          context: context,
          amount: cat.price,
          recipientName: 'Billetterie',
          reference: event.id,
          label: '${event.name} • ${cat.label}',
        );
        if (!ok || !mounted) return;
      }

      final now = DateTime.now().toIso8601String();
      final id = makeTicketId('evt');
      final typeId = 'event:${event.id}:${cat.id}';
      final typeName = '${event.name} — ${cat.label}';
      final qrPayload = buildTicketQrPayload(
        ticketId: id,
        typeId: typeId,
        typeName: typeName,
        holderName: 'Moi',
        note: 'Achat • 1 billet',
        amount: cat.price.toDouble(),
        currency: 'XOF',
        createdAt: now,
      );

      await _storage.addTicket(
        BilletterieTicket(
          id: id,
          typeId: typeId,
          typeName: typeName,
          holderName: 'Moi',
          note: 'Achat • 1 billet',
          amount: cat.price.toDouble(),
          currency: 'XOF',
          createdAt: now,
          qrPayload: qrPayload,
        ),
      );

      if (!mounted) return;
      widget.onPurchased(
        OrderSuccessArgs(eventName: event.name, ticketLabel: cat.label, total: cat.price),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  String _shortDate(String date) {
    final parts = date.split(' ');
    if (parts.length >= 3) return parts.sublist(1, 3).join(' ');
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)),
        body: Center(
          child: Text(
            _fetchComplete ? 'Évènement introuvable' : '',
            style: const TextStyle(color: BilletterieBrand.muted),
          ),
        ),
      );
    }

    final descriptionTruncated = event.description.length > _descriptionMaxLength && !_descriptionExpanded;
    final descriptionText = descriptionTruncated
        ? '${event.description.substring(0, _descriptionMaxLength)}...'
        : event.description;

    return Scaffold(
      backgroundColor: BilletterieBrand.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(event.eventType, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: BilletterieBrand.bg,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => _favorite = !_favorite),
            icon: Icon(
              _favorite ? Icons.favorite : Icons.favorite_border,
              color: _favorite ? BilletterieBrand.danger : BilletterieBrand.muted,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _FlyerCard(
                  event: event,
                  shortDate: _shortDate(event.date),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _MetaBlock(icon: Icons.location_on, label: 'Lieu', value: '${event.city} ${event.venue}')),
                    const SizedBox(width: 16),
                    Expanded(child: _MetaBlock(icon: Icons.schedule, label: 'Horaire', value: event.time)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(descriptionText, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), height: 22 / 14)),
                if (event.description.length > _descriptionMaxLength)
                  TextButton(
                    onPressed: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    child: Text(
                      _descriptionExpanded ? 'Voir moins' : 'Lire la suite',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: BilletterieBrand.primary),
                    ),
                  ),
                const SizedBox(height: 24),
                if (event.ticketCategories.length > 1) ...[
                  const Text('Type de billet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in event.ticketCategories)
                        _CategoryChip(
                          label: '${cat.label} · ${formatBilletterieCurrency(cat.price)}',
                          selected: _selected?.id == cat.id,
                          onTap: () => setState(() => _selected = cat),
                        ),
                    ],
                  ),
                ] else if (event.ticketCategories.length == 1) ...[
                  const Text('Billet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  Text(
                    '${event.ticketCategories.first.label} · ${formatBilletterieCurrency(event.ticketCategories.first.price)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ],
              ],
            ),
          ),
          _SlideToPayFooter(
            price: _selected != null ? formatBilletterieCurrency(_selected!.price) : '—',
            enabled: _selected != null && !_paying,
            paying: _paying,
            onPay: _pay,
          ),
        ],
      ),
    );
  }
}

class _FlyerCard extends StatelessWidget {
  const _FlyerCard({required this.event, required this.shortDate});

  final BilletterieEvent event;
  final String shortDate;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        constraints: const BoxConstraints(minHeight: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFE2E8F0),
          boxShadow: const [
            BoxShadow(color: Color(0x4D000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (event.flyerImage != null)
              Image.network(event.flyerImage!, fit: BoxFit.cover)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    event.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (event.rating != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text('${event.rating}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110,
              child: Container(
                color: const Color(0x73000000),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    if (event.interestedCount != null)
                      Text(
                        '${event.interestedCount}+ intéressés',
                        style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(shortDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
          ),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0x260EA5E9) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? const Color(0xFF0EA5E9) : BilletterieBrand.border, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? BilletterieBrand.primary : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideToPayFooter extends StatefulWidget {
  const _SlideToPayFooter({
    required this.price,
    required this.enabled,
    required this.paying,
    required this.onPay,
  });

  final String price;
  final bool enabled;
  final bool paying;
  final VoidCallback onPay;

  @override
  State<_SlideToPayFooter> createState() => _SlideToPayFooterState();
}

class _SlideToPayFooterState extends State<_SlideToPayFooter> {
  static const _thumbWidth = 52.0;
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: const BoxDecoration(
          color: BilletterieBrand.bg,
          border: Border(top: BorderSide(color: BilletterieBrand.border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth - 90 - 80 - 36;
            final maxDrag = (trackWidth - _thumbWidth - 8).clamp(0.0, double.infinity);

            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.price,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0C4A6E)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          Positioned(
                            left: 4 + _dragOffset,
                            top: 4,
                            child: GestureDetector(
                              onHorizontalDragUpdate: widget.enabled && !widget.paying
                                  ? (details) {
                                      setState(() {
                                        _dragOffset = (_dragOffset + details.delta.dx).clamp(0, maxDrag);
                                      });
                                    }
                                  : null,
                              onHorizontalDragEnd: widget.enabled && !widget.paying
                                  ? (_) {
                                      if (_dragOffset >= maxDrag * 0.85) {
                                        setState(() => _dragOffset = maxDrag);
                                        widget.onPay();
                                      }
                                      setState(() => _dragOffset = 0);
                                    }
                                  : null,
                              child: Container(
                                width: _thumbWidth,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text('››', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: FilledButton(
                      onPressed: widget.enabled && !widget.paying ? widget.onPay : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF006D56),
                        disabledBackgroundColor: const Color(0xFFB9D8CF),
                        minimumSize: const Size(80, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.paying ? '...' : 'Payer',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
