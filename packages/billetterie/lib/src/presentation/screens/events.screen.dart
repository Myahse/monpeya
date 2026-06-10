import 'package:flutter/material.dart';

import 'package:billetterie/src/presentation/constants/billetterie.brand.dart';
import 'package:billetterie/src/data/datasources/mock.events.dart';
import 'package:billetterie/src/data/models/billetterie.event.dart';
import 'package:billetterie/src/data/services/billetterie_api.service.dart';

const _cardMargin = 20.0;
const _arcHeight = 80.0;

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    this.onBack,
    required this.onEventTap,
  });

  final VoidCallback? onBack;
  final ValueChanged<String> onEventTap;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _api = BilletterieApiService();
  final _scrollController = ScrollController();
  List<BilletterieEvent> _events = mockBilletterieEvents;
  String _query = '';
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  Future<void> _load() async {
    final items = await _api.getEvents();
    if (!mounted) return;
    setState(() => _events = items);
  }

  List<BilletterieEvent> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _events;
    return _events
        .where((e) => e.name.toLowerCase().contains(q) || e.city.toLowerCase().contains(q))
        .toList();
  }

  String get _locationLabel {
    final cities = _filtered.map((e) => e.city).toList();
    if (cities.isEmpty) return 'Partout';
    final counts = <String, int>{};
    for (final c in cities) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    if (counts.length == 1) return counts.keys.first;
    return 'Partout';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width * 0.78;
    final cardHeight = 420.0;
    final cardFullWidth = cardWidth + _cardMargin * 2;
    final upcomingWidth = width * 0.42;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: BilletterieBrand.bg,
      body: RefreshIndicator(
              onRefresh: _load,
              color: BilletterieBrand.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 0),
                      child: Row(
                        children: [
                          if (widget.onBack != null)
                            IconButton(
                              padding: const EdgeInsets.all(8),
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                            )
                          else
                            IconButton(
                              padding: const EdgeInsets.all(8),
                              onPressed: () {},
                              icon: const Icon(Icons.grid_view_outlined, color: Color(0xFF1E293B)),
                            ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: BilletterieBrand.primary),
                                const SizedBox(width: 6),
                                Text(
                                  _locationLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: Icon(Icons.person, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Rechercher...',
                                  hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                                onChanged: (v) => setState(() => _query = v),
                              ),
                            ),
                            Icon(Icons.mic_none, size: 20, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Près de vous',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Voir tout',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BilletterieBrand.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: cardHeight + _arcHeight + 32,
                      child: _filtered.isEmpty
                          ? const Center(child: Text('Aucun événement', style: TextStyle(color: BilletterieBrand.muted)))
                          : ListView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: (width - cardWidth) / 2 - _cardMargin,
                                vertical: _arcHeight + 16,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final event = _filtered[index];
                                final position = _scrollOffset / cardFullWidth;
                                final distance = (index - position).abs().clamp(0.0, 1.0);
                                final scale = 1.0 - 0.15 * distance;
                                final opacity = 1.0 - 0.4 * distance;
                                final translateY = _arcHeight * distance;

                                return SizedBox(
                                  width: cardFullWidth,
                                  child: Center(
                                    child: Transform.translate(
                                      offset: Offset(0, translateY),
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Opacity(
                                          opacity: opacity,
                                          child: _ArcEventCard(
                                            event: event,
                                            width: cardWidth,
                                            height: cardHeight,
                                            onTap: () => widget.onEventTap(event.id),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'À venir',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Voir tout',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BilletterieBrand.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return _UpcomingCard(
                            event: event,
                            width: upcomingWidth,
                            onTap: () => widget.onEventTap(event.id),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }
}

class _ArcEventCard extends StatelessWidget {
  const _ArcEventCard({
    required this.event,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final BilletterieEvent event;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFE2E8F0),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (event.flyerImage != null)
              Image.network(event.flyerImage!, fit: BoxFit.cover)
            else
              Center(child: Text(event.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0x73000000),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Color(0xE6FFFFFF)),
                        const SizedBox(width: 4),
                        Text(event.city, style: const TextStyle(fontSize: 12, color: Color(0xE6FFFFFF))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.event,
    required this.width,
    required this.onTap,
  });

  final BilletterieEvent event;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minPrice = event.ticketCategories.isEmpty
        ? null
        : event.ticketCategories.map((c) => c.price).reduce((a, b) => a < b ? a : b);
    final title = event.name.split('–').first.trim().isEmpty ? event.name : event.name.split('–').first.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.flyerImage != null)
              Image.network(event.flyerImage!, height: 220, fit: BoxFit.cover)
            else
              Container(
                height: 220,
                color: const Color(0xFFE2E8F0),
                alignment: Alignment.center,
                child: Text(
                  event.name.length >= 2 ? event.name.substring(0, 2).toUpperCase() : event.name,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                  ),
                  Text(
                    minPrice != null ? formatBilletterieCurrency(minPrice) : '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BilletterieBrand.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
