import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/event/screens/event_details.screen.dart';
import 'package:billetterie/src/features/event/widgets/event_bottom_nav.widget.dart';
import 'package:billetterie/src/features/event/widgets/event_datetime_range_sheet.widget.dart';
import 'package:billetterie/src/features/event/widgets/event_ui_chrome.dart';

/// Client home — event discovery layout (header, categories, featured, recs).
class EventClientHomeView extends StatefulWidget {
  const EventClientHomeView({super.key});

  @override
  State<EventClientHomeView> createState() => _EventClientHomeViewState();
}

class _EventClientHomeViewState extends State<EventClientHomeView> {
  static const _categories = [
    'Tous',
    'Concerts',
    'Festivals',
    'Ballet',
    'Théâtre',
  ];

  DateTime? _filterStart;
  DateTime? _filterEnd;
  String _category = _categories.first;
  String _city = 'Abidjan';
  String _greetingName = BilletterieHostBridge.guestDisplayName;

  @override
  void initState() {
    super.initState();
    BilletterieHostBridge.sessionChanges?.addListener(_onHostSessionChanged);
    _loadIdentity();
  }

  @override
  void dispose() {
    BilletterieHostBridge.sessionChanges?.removeListener(_onHostSessionChanged);
    super.dispose();
  }

  void _onHostSessionChanged() => _loadIdentity();

  Future<void> _loadIdentity() async {
    const guest = BilletterieHostBridge.guestDisplayName;
    try {
      final id = await BilletterieHostBridge.resolveClientOrNull();
      if (!mounted) return;
      if (id == null) {
        setState(() => _greetingName = guest);
        return;
      }
      final name = (id.firstName?.trim().isNotEmpty == true)
          ? id.firstName!.trim()
          : (id.displayName?.trim().isNotEmpty == true
              ? id.displayName!.trim().split(' ').first
              : guest);
      setState(() => _greetingName = name.isEmpty ? guest : name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _greetingName = guest);
    }
  }

  bool get _hasFilter => _filterStart != null && _filterEnd != null;

  Future<void> _openFilter() async {
    final now = DateTime.now();
    final initialStart = _filterStart ??
        DateTime(now.year, now.month, now.day, now.hour);
    final initialEnd =
        _filterEnd ?? initialStart.add(const Duration(hours: 6));

    final result = await showEventDateTimeRangeSheet(
      context: context,
      initialStart: initialStart,
      initialEnd: initialEnd,
      title: 'Filtrer',
      confirmLabel: 'Appliquer le filtre',
    );

    if (!mounted || result == null) return;
    setState(() {
      _filterStart = result.start;
      _filterEnd = result.end;
    });
  }

  void _clearFilter() {
    setState(() {
      _filterStart = null;
      _filterEnd = null;
    });
  }

  void _openDetails(EventDetailsData data) {
    openEventDetails(context, data);
  }

  static const _featuredDetails = EventDetailsData(
    id: 'EVT-NEON-2402',
    title: 'Neon Brush: Paint in the dark',
    imageUrl:
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=900&q=80',
    dateTimeLabel: 'Samedi 2 nov. · 19:00',
    description:
        'Plongez dans une soirée de peinture néon en pleine lumière noire. '
        'Matériel fourni — venez créer, danser et partager un moment unique '
        'au Novotel Abidjan City.',
    place: 'Novotel Abidjan City, Boulevard de la République, Abidjan, Côte d’Ivoire',
    availableTickets: 48,
    ticketNumber: 'EVT-NEON-2402',
    city: 'Abidjan',
    latitude: 5.3197,
    longitude: -4.0267,
  );

  static const _featuredCards = [
    (
      data: _featuredDetails,
      badge: 'À LA UNE',
      region: 'ABIDJAN — COCODY',
      title: 'Neon Brush',
      rating: '4.9k',
      duration: '1 soir',
      price: 'Dès 5 000',
    ),
    (
      data: EventDetailsData(
        id: 'EVT-SUNSET-2405',
        title: 'Sunset Beats',
        imageUrl:
            'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?auto=format&fit=crop&w=900&q=80',
        dateTimeLabel: 'Mardi 5 nov. · 18:00',
        description:
            'Un coucher de soleil en musique au bord de la lagune. DJs live, '
            'food trucks et ambiance chill jusqu’à la nuit.',
        place: 'Cocody Bay, Abidjan, Côte d’Ivoire',
        availableTickets: 120,
        ticketNumber: 'EVT-SUNSET-2405',
        city: 'Abidjan',
        latitude: 5.3600,
        longitude: -3.9780,
      ),
      badge: 'TENDANCE',
      region: 'ABIDJAN — LAGUNE',
      title: 'Sunset Beats',
      rating: '4.8k',
      duration: '1 soir',
      price: 'Dès 3 500',
    ),
  ];

  static const _recoDetails = [
    EventDetailsData(
      id: 'EVT-SUNSET-2405',
      title: 'Sunset Beats',
      imageUrl:
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?auto=format&fit=crop&w=700&q=80',
      dateTimeLabel: 'Mardi 5 nov. · 18:00',
      description:
          'Un coucher de soleil en musique au bord de la lagune. DJs live, '
          'food trucks et ambiance chill jusqu’à la nuit.',
      place: 'Cocody Bay, Abidjan, Côte d’Ivoire',
      availableTickets: 120,
      ticketNumber: 'EVT-SUNSET-2405',
      city: 'Abidjan',
      latitude: 5.3600,
      longitude: -3.9780,
    ),
    EventDetailsData(
      id: 'EVT-OPENMIC-2408',
      title: 'Open Mic Night',
      imageUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=700&q=80',
      dateTimeLabel: 'Vendredi 8 nov. · 20:30',
      description:
          'Scène ouverte pour poètes, stand-up et musiciens. Inscrivez-vous '
          'sur place ou réservez votre place dans le public.',
      place: 'Plateau Hub, Abidjan, Côte d’Ivoire',
      availableTickets: 35,
      ticketNumber: 'EVT-OPENMIC-2408',
      city: 'Abidjan',
      latitude: 5.3260,
      longitude: -4.0200,
    ),
    EventDetailsData(
      id: 'EVT-ARTWALK-2412',
      title: 'Art Walk',
      imageUrl:
          'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?auto=format&fit=crop&w=700&q=80',
      dateTimeLabel: 'Mardi 12 nov. · 16:00',
      description:
          'Parcours guidé dans les galeries du Sud. Découvrez artistes locaux, '
          'installations et vernissages exclusifs.',
      place: 'Galerie Sud, Abidjan, Côte d’Ivoire',
      availableTickets: 60,
      ticketNumber: 'EVT-ARTWALK-2412',
      city: 'Abidjan',
      latitude: 5.2900,
      longitude: -3.9800,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final chrome = EventUiChrome.of(context);
    final bottomPad = BilletterieEventBottomNav.contentBottomPadding(context);
    final name = _greetingName.isEmpty
        ? BilletterieHostBridge.guestDisplayName
        : _greetingName;
    final accent = brand.primaryDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: chrome.statusStyle,
      child: ColoredBox(
        color: chrome.scaffold,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed top through genre chips.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _DiscoverTopBar(
                  chrome: chrome,
                  accent: accent,
                  city: _city,
                  onCityTap: () {},
                  onNotify: () {},
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '—  BON RETOUR',
                      style: TextStyle(
                        color: chrome.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: chrome.text,
                          fontWeight: FontWeight.w500,
                          fontSize: 30,
                          height: 1.2,
                          fontFamily: 'serif',
                        ),
                        children: [
                          const TextSpan(text: 'Où allons-nous '),
                          TextSpan(
                            text: 'sortir',
                            style: TextStyle(
                              color: accent,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'serif',
                              fontSize: 32,
                            ),
                          ),
                          TextSpan(text: ', $name ?'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchBar(
                  chrome: chrome,
                  accent: accent,
                  filterActive: _hasFilter,
                  onFilter: _openFilter,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final label = _categories[index];
                    final selected = label == _category;
                    return _DiscoverChip(
                      chrome: chrome,
                      label: label,
                      selected: selected,
                      accent: accent,
                      onTap: () => setState(() => _category = label),
                    );
                  },
                ),
              ),
              // Scrollable content below genres.
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: 14, bottom: bottomPad + 8),
                  children: [
                    if (_hasFilter) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ActiveFilterBanner(
                          brand: brand,
                          accent: accent,
                          label:
                              'Du ${formatEventDateTime(_filterStart!)} au ${formatEventDateTime(_filterEnd!)}',
                          onEdit: _openFilter,
                          onClear: _clearFilter,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Builder(
                      builder: (context) {
                        final cardSize =
                            MediaQuery.sizeOf(context).width - 56;
                        return SizedBox(
                          height: cardSize,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _featuredCards.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final card = _featuredCards[index];
                              return SizedBox(
                                width: cardSize,
                                child: GestureDetector(
                                  onTap: () => _openDetails(card.data),
                                  child: _FeaturedDiscoverCard(
                                    chrome: chrome,
                                    accent: accent,
                                    badge: card.badge,
                                    region: card.region,
                                    title: card.title,
                                    imageUrl: card.data.imageUrl,
                                    rating: card.rating,
                                    duration: card.duration,
                                    price: card.price,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: chrome.text,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 26,
                                  fontFamily: 'serif',
                                ),
                                children: [
                                  const TextSpan(text: 'Tendances '),
                                  TextSpan(
                                    text: 'du moment',
                                    style: TextStyle(
                                      color: accent,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: chrome.muted,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'VOIR TOUT →',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 168,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _recoDetails.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = _recoDetails[index];
                          final tags = ['FESTIVAL', 'CONCERT', 'ART'];
                          return GestureDetector(
                            onTap: () => _openDetails(item),
                            child: _TrendingCard(
                              chrome: chrome,
                              title: item.title,
                              tag: tags[index % tags.length],
                              imageUrl: item.imageUrl,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverTopBar extends StatelessWidget {
  const _DiscoverTopBar({
    required this.chrome,
    required this.accent,
    required this.city,
    required this.onCityTap,
    required this.onNotify,
  });

  final EventUiChrome chrome;
  final Color accent;
  final String city;
  final VoidCallback onCityTap;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 10,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: chrome.surface,
            child: Icon(
              Icons.person_rounded,
              color: chrome.iconOnSurface,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onCityTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ma position',
                      style: TextStyle(
                        color: chrome.muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: chrome.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: accent, size: 15),
                    const SizedBox(width: 2),
                    Text(
                      city,
                      style: TextStyle(
                        color: chrome.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onNotify,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: chrome.border),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: chrome.iconOnSurface,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.chrome,
    required this.accent,
    required this.filterActive,
    required this.onFilter,
  });

  final EventUiChrome chrome;
  final Color accent;
  final bool filterActive;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: chrome.searchFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: chrome.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: chrome.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rechercher un événement…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chrome.muted,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFilter,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: filterActive ? 0.55 : 0.25),
                      chrome.brand.primary
                          .withValues(alpha: filterActive ? 0.55 : 0.25),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Filtrer',
                      style: TextStyle(
                        color: chrome.isLight ? chrome.text : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverChip extends StatelessWidget {
  const _DiscoverChip({
    required this.chrome,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final EventUiChrome chrome;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : chrome.chipIdle,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? accent : chrome.chipIdleBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? chrome.chipSelectedFg : chrome.chipIdleFg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedDiscoverCard extends StatelessWidget {
  const _FeaturedDiscoverCard({
    required this.chrome,
    required this.accent,
    required this.badge,
    required this.region,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.duration,
    required this.price,
  });

  final EventUiChrome chrome;
  final Color accent;
  final String badge;
  final String region;
  final String title;
  final String imageUrl;
  final String rating;
  final String duration;
  final String price;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: chrome.surface,
                child: Icon(Icons.celebration_outlined,
                    size: 48, color: chrome.muted),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _GlassPill(label: badge),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _CircleIconButton(icon: Icons.bookmark_border_rounded),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      fontFamily: 'serif',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(icon: Icons.star_rounded, label: rating),
                      _MetaPill(
                          icon: Icons.schedule_rounded, label: duration),
                      _MetaPill(icon: Icons.payments_outlined, label: price),
                    ],
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

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.chrome,
    required this.title,
    required this.tag,
    required this.imageUrl,
  });

  final EventUiChrome chrome;
  final String title;
  final String tag;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: chrome.surface,
                child: Icon(Icons.event, color: chrome.muted),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB3000000)],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: _GlassPill(label: tag, compact: true),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _CircleIconButton(
                icon: Icons.favorite_border_rounded,
                compact: true,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 9 : 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.compact = false});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 38.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: compact ? 16 : 18),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterBanner extends StatelessWidget {
  const _ActiveFilterBanner({
    required this.brand,
    required this.accent,
    required this.label,
    required this.onEdit,
    required this.onClear,
  });

  final BilletterieBrand brand;
  final Color accent;
  final String label;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: brand.text,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Effacer',
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  color: brand.muted,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
