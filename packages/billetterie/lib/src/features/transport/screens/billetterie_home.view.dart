import 'package:flutter/material.dart';

import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/shared/widgets/billetterie_bottom_nav.widget.dart';
import 'package:billetterie/src/shared/widgets/billetterie_enter.widget.dart';
import 'package:billetterie/src/features/transport/screens/ticket_details.screen.dart';
import 'package:billetterie/src/features/transport/widgets/transport_ticket_front.widget.dart';

/// Home — display divided into Destinations / Prix / Tous les trajets.
class BilletterieHomeView extends StatefulWidget {
  const BilletterieHomeView({
    super.key,
    required this.tickets,
    this.guestMode = false,
  });

  final List<BilletterieTransportTicket> tickets;

  /// When true, shows browse-only copy (login happens at purchase).
  final bool guestMode;

  @override
  State<BilletterieHomeView> createState() => _BilletterieHomeViewState();
}

class _BilletterieHomeViewState extends State<BilletterieHomeView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();

  /// Draft text in the search field (not applied until filter Confirm).
  String _searchDraft = '';

  /// Applied filters (from the filter sheet).
  String _appliedQuery = '';
  String? _selectedRoute;
  _PriceSort _priceSort = _PriceSort.cheapest;

  late final AnimationController _enter;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _searchFade;
  late final Animation<Offset> _searchSlide;
  late final Animation<double> _destFade;
  late final Animation<Offset> _destSlide;
  late final Animation<double> _pricesFade;
  late final Animation<Offset> _pricesSlide;
  late final Animation<double> _allFade;
  late final Animation<Offset> _allSlide;

  bool get _hasActiveFilter =>
      _appliedQuery.isNotEmpty ||
      _selectedRoute != null ||
      _priceSort != _PriceSort.cheapest;

  Animation<double> _fade(double begin, double end) => CurvedAnimation(
        parent: _enter,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  Animation<Offset> _slide(double begin, double end, {Offset from = const Offset(0, 0.12)}) =>
      Tween<Offset>(begin: from, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _enter,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _titleFade = _fade(0.00, 0.32);
    _titleSlide = _slide(0.00, 0.32, from: const Offset(0, -0.08));
    _searchFade = _fade(0.14, 0.46);
    _searchSlide = _slide(0.14, 0.46);
    _destFade = _fade(0.28, 0.60);
    _destSlide = _slide(0.28, 0.60);
    _pricesFade = _fade(0.42, 0.76);
    _pricesSlide = _slide(0.42, 0.76);
    _allFade = _fade(0.54, 0.92);
    _allSlide = _slide(0.54, 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enter.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _enter.dispose();
    super.dispose();
  }

  String _routeKey(BilletterieTransportTicket t) => '${t.fromCode} → ${t.toCode}';

  List<String> get _allRouteKeys {
    final keys = <String>{};
    for (final t in widget.tickets) {
      keys.add(_routeKey(t));
    }
    return keys.toList()..sort();
  }

  List<BilletterieTransportTicket> get _filtered {
    var list = widget.tickets.where((t) {
      if (_selectedRoute != null && _routeKey(t) != _selectedRoute) {
        return false;
      }
      final q = _appliedQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return t.fromCode.toLowerCase().contains(q) ||
          t.toCode.toLowerCase().contains(q) ||
          t.fromCity.toLowerCase().contains(q) ||
          t.toCity.toLowerCase().contains(q) ||
          t.vehicleNumber.toLowerCase().contains(q) ||
          t.price.toString().contains(q);
    }).toList();

    if (_priceSort == _PriceSort.highToLow) {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    return list;
  }

  /// Destination row uses full catalog (not search-filtered) so it stays stable.
  List<({String key, BilletterieTransportTicket ticket, int count})>
      get _destinationSummaries {
    final map = <String, List<BilletterieTransportTicket>>{};
    for (final t in widget.tickets) {
      map.putIfAbsent(_routeKey(t), () => []).add(t);
    }
    final summaries = map.entries.map((e) {
      final cheapest = e.value.reduce((a, b) => a.price <= b.price ? a : b);
      return (key: e.key, ticket: cheapest, count: e.value.length);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return summaries;
  }

  List<BilletterieTransportTicket> get _bestPrices => _filtered.take(4).toList();

  List<BilletterieTransportTicket> get _allTrajets => _filtered;

  void _openTicketDetails(
    BilletterieTransportTicket ticket,
    BilletterieTicketBadge? badge,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TicketDetailsScreen(ticket: ticket, badge: badge),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final routes = _allRouteKeys;
    var draftRoute = _selectedRoute;
    var draftSort = _priceSort;
    var draftQuery = _searchDraft;
    final brand = BilletterieBrand.of(context);
    final brightness = Theme.of(context).brightness;

    final result = await showModalBottomSheet<_HomeFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: brand.card,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: brand.text,
              fontWeight: FontWeight.w600,
            );
        return Theme(
          data: Theme.of(context).copyWith(
            brightness: brightness,
            colorScheme: ColorScheme.fromSeed(
              seedColor: brand.primaryDark,
              brightness: brightness,
            ),
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: brand.text,
                  displayColor: brand.text,
                ),
            chipTheme: ChipThemeData(
              backgroundColor: brand.card,
              selectedColor: brand.primarySoft,
              disabledColor: brand.border,
              labelStyle: labelStyle,
              secondaryLabelStyle: labelStyle,
              side: BorderSide(color: brand.border),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: brand.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Filtres',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: brand.text,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recherche',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: brand.text,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: draftQuery,
                          onChanged: (v) => draftQuery = v,
                          style: TextStyle(color: brand.text),
                          decoration: InputDecoration(
                            hintText: 'Mot-clé, code, véhicule…',
                            hintStyle: TextStyle(color: brand.muted),
                            filled: true,
                            fillColor: brand.searchFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Destination',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: brand.text,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text(
                                'Tous',
                                style: TextStyle(
                                  color: brand.text,
                                  fontWeight: draftRoute == null
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: draftRoute == null,
                              showCheckmark: false,
                              backgroundColor: brand.card,
                              selectedColor: brand.primarySoft,
                              side: BorderSide(
                                color: draftRoute == null
                                    ? brand.primaryDark
                                    : brand.border,
                              ),
                              onSelected: (_) =>
                                  setModalState(() => draftRoute = null),
                            ),
                            ...routes.map((key) {
                              final selected = draftRoute == key;
                              return FilterChip(
                                label: Text(
                                  key,
                                  style: TextStyle(
                                    color: brand.text,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: selected,
                                showCheckmark: false,
                                backgroundColor: brand.card,
                                selectedColor: brand.primarySoft,
                                side: BorderSide(
                                  color: selected
                                      ? brand.primaryDark
                                      : brand.border,
                                ),
                                onSelected: (_) => setModalState(() {
                                  draftRoute = selected ? null : key;
                                }),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Prix',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: brand.text,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ..._PriceSort.values.map((sort) {
                          final selected = draftSort == sort;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              sort.label,
                              style: TextStyle(
                                color: brand.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: selected
                                ? Icon(
                                    Icons.check,
                                    color: brand.primaryDark,
                                  )
                                : null,
                            onTap: () => setModalState(() => draftSort = sort),
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    const _HomeFilterResult(
                                      query: '',
                                      route: null,
                                      sort: _PriceSort.cheapest,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: brand.text,
                                  side: BorderSide(
                                    color: brand.border,
                                  ),
                                ),
                                child: const Text('Réinitialiser'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    _HomeFilterResult(
                                      query: draftQuery.trim(),
                                      route: draftRoute,
                                      sort: draftSort,
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: brand.primaryDark,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Appliquer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _appliedQuery = result.query;
      _searchDraft = result.query;
      _searchController.text = result.query;
      _selectedRoute = result.route;
      _priceSort = result.sort;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinationSummaries;
    final bestPrices = _bestPrices;
    final allTrajets = _allTrajets;
    final badges = computeTicketBadges(widget.tickets);
    final brand = BilletterieBrand.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BilletterieEnter(
          fade: _titleFade,
          slide: _titleSlide,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeTitle(
                  widget.guestMode
                      ? 'Billets disponibles'
                      : 'Ticket - transports',
                ),
                if (widget.guestMode) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Mode invité — connectez-vous uniquement pour payer.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: brand.muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        BilletterieEnter(
          fade: _searchFade,
          slide: _searchSlide,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _searchDraft = value,
                    onSubmitted: (_) => _openFilterSheet(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un trajet…',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: brand.muted,
                          ),
                      filled: true,
                      fillColor: brand.searchFill,
                      suffixIcon: Icon(
                        Icons.search_rounded,
                        color: brand.muted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Badge(
                  isLabelVisible: _hasActiveFilter,
                  smallSize: 8,
                  backgroundColor: brand.primaryDark,
                  child: IconButton(
                    onPressed: _openFilterSheet,
                    icon: const Icon(Icons.filter_list_rounded, size: 28),
                    color: brand.text,
                    style: IconButton.styleFrom(
                      backgroundColor: _hasActiveFilter
                          ? brand.primarySoft
                          : Colors.transparent,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_hasActiveFilter) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_appliedQuery.isNotEmpty)
                  _ActiveFilterChip(
                    label: '“$_appliedQuery”',
                    onClear: () => setState(() {
                      _appliedQuery = '';
                      _searchDraft = '';
                      _searchController.clear();
                    }),
                  ),
                if (_selectedRoute != null)
                  _ActiveFilterChip(
                    label: _selectedRoute!,
                    onClear: () => setState(() {
                      _selectedRoute = null;
                    }),
                  ),
                if (_priceSort != _PriceSort.cheapest)
                  _ActiveFilterChip(
                    label: _priceSort.label,
                    onClear: () => setState(() {
                      _priceSort = _PriceSort.cheapest;
                    }),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        BilletterieEnter(
          fade: _destFade,
          slide: _destSlide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'Destinations',
                  subtitle: 'Par trajet',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 108,
                child: destinations.isEmpty
                    ? const Center(child: Text('Aucune destination'))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: destinations.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final d = destinations[index];
                          final selected = _selectedRoute == d.key;
                          return _DestinationCard(
                            routeLabel: d.key,
                            from: d.ticket.fromCode,
                            to: d.ticket.toCode,
                            minPrice: d.ticket.price,
                            offerCount: d.count,
                            selected: selected,
                            onTap: _openFilterSheet,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _SectionDivider(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              8,
              0,
              BilletterieBottomNav.contentBottomPadding(context),
            ),
            children: [
              BilletterieEnter(
                fade: _pricesFade,
                slide: _pricesSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: _SectionHeader(
                        title: 'Meilleurs prix',
                        subtitle: 'Selon vos filtres',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (bestPrices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Aucun résultat',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: brand.muted,
                                ),
                          ),
                        ),
                      )
                    else
                      ...bestPrices.map((ticket) {
                        final i = widget.tickets.indexOf(ticket);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TransportTicketFront(
                            ticket: ticket,
                            badge: badges[i],
                            onTap: () => _openTicketDetails(ticket, badges[i]),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const _SectionDivider(),
              BilletterieEnter(
                fade: _allFade,
                slide: _allSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _SectionHeader(
                        title: _selectedRoute == null
                            ? 'Tous les trajets'
                            : _selectedRoute!,
                        subtitle:
                            '${allTrajets.length} offre${allTrajets.length > 1 ? 's' : ''}',
                        trailing: !_hasActiveFilter
                            ? null
                            : TextButton(
                                onPressed: () => setState(() {
                                  _appliedQuery = '';
                                  _searchDraft = '';
                                  _searchController.clear();
                                  _selectedRoute = null;
                                  _priceSort = _PriceSort.cheapest;
                                }),
                                child: const Text('Effacer'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (allTrajets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Aucun trajet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: brand.muted,
                                ),
                          ),
                        ),
                      )
                    else
                      ...allTrajets.map((ticket) {
                        final i = widget.tickets.indexOf(ticket);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TransportTicketFront(
                            ticket: ticket,
                            badge: badges[i],
                            onTap: () => _openTicketDetails(ticket, badges[i]),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _PriceSort { cheapest, lowToHigh, highToLow }

extension on _PriceSort {
  String get label => switch (this) {
        _PriceSort.cheapest => 'Moins chère',
        _PriceSort.lowToHigh => 'Prix croissant',
        _PriceSort.highToLow => 'Prix décroissant',
      };
}

class _HomeFilterResult {
  const _HomeFilterResult({
    required this.query,
    required this.route,
    required this.sort,
  });

  final String query;
  final String? route;
  final _PriceSort sort;
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return InputChip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: brand.text,
            ),
      ),
      onDeleted: onClear,
      deleteIconColor: brand.text,
      backgroundColor: brand.primarySoft,
      side: BorderSide(color: brand.primaryDark),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: brand.text,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: brand.muted,
                    ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: BilletterieBrand.of(context).border,
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.routeLabel,
    required this.from,
    required this.to,
    required this.minPrice,
    required this.offerCount,
    required this.selected,
    required this.onTap,
  });

  final String routeLabel;
  final String from;
  final String to;
  final int minPrice;
  final int offerCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Material(
      color: selected ? brand.primarySoft : brand.card,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 168,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? brand.primaryDark : brand.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    from,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: brand.text,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 14, color: brand.muted),
                  ),
                  Text(
                    to,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: brand.text,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'dès $minPrice Fcfa',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: brand.text,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '$offerCount offre${offerCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: brand.muted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: BilletterieBrand.of(context).text,
          ),
    );
  }
}
