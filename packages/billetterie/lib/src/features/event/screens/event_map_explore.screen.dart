import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/event/screens/event_details.screen.dart';
import 'package:billetterie/src/features/event/widgets/event_bottom_nav.widget.dart';
import 'package:billetterie/src/shared/services/billetterie_location.service.dart';
import 'package:billetterie/src/shared/widgets/billetterie_location_modal.widget.dart';
import 'package:billetterie/src/shared/widgets/billetterie_user_sonar_marker.widget.dart';

class _MapPlace {
  const _MapPlace({
    required this.data,
    required this.shortLabel,
    required this.tag,
    required this.rating,
    required this.distanceKm,
    required this.point,
  });

  final EventDetailsData data;
  final String shortLabel;
  final String tag;
  final String rating;
  final String distanceKm;
  final LatLng point;
}

class _MapChrome {
  const _MapChrome({
    required this.isLight,
    required this.accent,
    required this.scaffold,
    required this.mapBg,
    required this.tileUrl,
    required this.panel,
    required this.panelBorder,
    required this.fg,
    required this.fgMuted,
    required this.chipIdle,
    required this.chipIdleBorder,
    required this.chipIdleFg,
    required this.markerLabelBg,
    required this.markerLabelBorder,
    required this.markerLabelFg,
    required this.markerRingIdle,
    required this.statusStyle,
  });

  factory _MapChrome.of(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final isLight =
        MediaQuery.platformBrightnessOf(context) == Brightness.light;
    final accent = brand.primaryDark;

    if (isLight) {
      return _MapChrome(
        isLight: true,
        accent: accent,
        scaffold: brand.bg,
        mapBg: const Color(0xFFF1F5F9),
        tileUrl:
            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
        panel: Colors.white.withValues(alpha: 0.88),
        panelBorder: brand.border,
        fg: brand.text,
        fgMuted: brand.muted,
        chipIdle: Colors.white.withValues(alpha: 0.92),
        chipIdleBorder: brand.border,
        chipIdleFg: brand.text.withValues(alpha: 0.75),
        markerLabelBg: Colors.white.withValues(alpha: 0.95),
        markerLabelBorder: brand.border,
        markerLabelFg: brand.text,
        markerRingIdle: Colors.white,
        statusStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    }

    return _MapChrome(
      isLight: false,
      accent: accent,
      scaffold: Colors.black,
      mapBg: const Color(0xFF0B0B0D),
      tileUrl: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      panel: Colors.black.withValues(alpha: 0.45),
      panelBorder: Colors.white12,
      fg: Colors.white,
      fgMuted: Colors.white.withValues(alpha: 0.45),
      chipIdle: Colors.black.withValues(alpha: 0.55),
      chipIdleBorder: Colors.white24,
      chipIdleFg: Colors.white.withValues(alpha: 0.7),
      markerLabelBg: Colors.black.withValues(alpha: 0.75),
      markerLabelBorder: Colors.white24,
      markerLabelFg: Colors.white,
      markerRingIdle: Colors.white,
      statusStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  final bool isLight;
  final Color accent;
  final Color scaffold;
  final Color mapBg;
  final String tileUrl;
  final Color panel;
  final Color panelBorder;
  final Color fg;
  final Color fgMuted;
  final Color chipIdle;
  final Color chipIdleBorder;
  final Color chipIdleFg;
  final Color markerLabelBg;
  final Color markerLabelBorder;
  final Color markerLabelFg;
  final Color markerRingIdle;
  final SystemUiOverlayStyle statusStyle;
}

/// Map explore — photo markers + nearby finds sheet (light/dark).
class EventMapExploreScreen extends StatefulWidget {
  const EventMapExploreScreen({super.key});

  @override
  State<EventMapExploreScreen> createState() => _EventMapExploreScreenState();
}

class _EventMapExploreScreenState extends State<EventMapExploreScreen>
    with AutomaticKeepAliveClientMixin {
  static const _abidjan = LatLng(5.3364, -4.0267);

  static const _categories = [
    (label: 'Tous', icon: Icons.near_me_rounded),
    (label: 'Concerts', icon: Icons.music_note_rounded),
    (label: 'Festivals', icon: Icons.celebration_rounded),
    (label: 'Théâtre', icon: Icons.theater_comedy_rounded),
    (label: 'Art', icon: Icons.palette_rounded),
  ];

  static final _places = <_MapPlace>[
    _MapPlace(
      data: const EventDetailsData(
        id: 'EVT-NEON-2402',
        title: 'Neon Brush',
        imageUrl:
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=600&q=80',
        dateTimeLabel: 'Samedi 2 nov. · 19:00',
        description: 'Soirée peinture néon au Novotel.',
        place: 'Novotel Abidjan City, Abidjan',
        availableTickets: 48,
        ticketNumber: 'EVT-NEON-2402',
        latitude: 5.3197,
        longitude: -4.0267,
      ),
      shortLabel: 'Novotel',
      tag: 'À LA UNE',
      rating: '4.9',
      distanceKm: '1.2 km',
      point: const LatLng(5.3197, -4.0267),
    ),
    _MapPlace(
      data: const EventDetailsData(
        id: 'EVT-SUNSET-2405',
        title: 'Sunset Beats',
        imageUrl:
            'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?auto=format&fit=crop&w=600&q=80',
        dateTimeLabel: 'Mardi 5 nov. · 18:00',
        description: 'Coucher de soleil en musique.',
        place: 'Cocody Bay, Abidjan',
        availableTickets: 120,
        ticketNumber: 'EVT-SUNSET-2405',
        latitude: 5.3600,
        longitude: -3.9780,
      ),
      shortLabel: 'Cocody Bay',
      tag: 'FESTIVAL',
      rating: '4.8',
      distanceKm: '3.1 km',
      point: const LatLng(5.3600, -3.9780),
    ),
    _MapPlace(
      data: const EventDetailsData(
        id: 'EVT-OPENMIC-2408',
        title: 'Open Mic Night',
        imageUrl:
            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=600&q=80',
        dateTimeLabel: 'Vendredi 8 nov. · 20:30',
        description: 'Scène ouverte Plateau.',
        place: 'Plateau Hub, Abidjan',
        availableTickets: 35,
        ticketNumber: 'EVT-OPENMIC-2408',
        latitude: 5.3260,
        longitude: -4.0200,
      ),
      shortLabel: 'Plateau',
      tag: 'CONCERT',
      rating: '4.7',
      distanceKm: '0.8 km',
      point: const LatLng(5.3260, -4.0200),
    ),
    _MapPlace(
      data: const EventDetailsData(
        id: 'EVT-ARTWALK-2412',
        title: 'Art Walk',
        imageUrl:
            'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?auto=format&fit=crop&w=600&q=80',
        dateTimeLabel: 'Mardi 12 nov. · 16:00',
        description: 'Parcours galeries du Sud.',
        place: 'Galerie Sud, Abidjan',
        availableTickets: 60,
        ticketNumber: 'EVT-ARTWALK-2412',
        latitude: 5.2900,
        longitude: -3.9800,
      ),
      shortLabel: 'Galerie Sud',
      tag: 'ART',
      rating: '4.6',
      distanceKm: '4.4 km',
      point: const LatLng(5.2900, -3.9800),
    ),
    _MapPlace(
      data: const EventDetailsData(
        id: 'EVT-JAZZ-2415',
        title: 'Jazz Terrace',
        imageUrl:
            'https://images.unsplash.com/photo-1415201364774-f6f0bb35beb0?auto=format&fit=crop&w=600&q=80',
        dateTimeLabel: 'Jeudi 15 nov. · 21:00',
        description: 'Jazz live en terrasse.',
        place: 'Zone 4, Abidjan',
        availableTickets: 22,
        ticketNumber: 'EVT-JAZZ-2415',
        latitude: 5.3450,
        longitude: -3.9950,
      ),
      shortLabel: 'Zone 4',
      tag: 'JAZZ',
      rating: '4.9',
      distanceKm: '2.0 km',
      point: const LatLng(5.3450, -3.9950),
    ),
  ];

  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _geo = Distance();
  String _category = _categories.first.label;
  String? _selectedId;
  LatLng _center = _abidjan;
  LatLng? _userPoint;
  bool _showUserSonar = false;
  bool _recentering = false;
  bool _didInitialCamera = false;

  static const _myLocationZoom = 15.5;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocation());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<_MapPlace> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final out = _places.where((p) {
      final catOk = _category == 'Tous' ||
          p.tag.toLowerCase().contains(_category.toLowerCase()) ||
          (_category == 'Art' && p.tag == 'ART') ||
          (_category == 'Concerts' &&
              (p.tag == 'CONCERT' || p.tag == 'JAZZ')) ||
          (_category == 'Festivals' && p.tag == 'FESTIVAL') ||
          (_category == 'Théâtre' && p.tag == 'À LA UNE');
      if (!catOk) return false;
      if (q.isEmpty) return true;
      return p.data.title.toLowerCase().contains(q) ||
          p.shortLabel.toLowerCase().contains(q) ||
          p.data.place.toLowerCase().contains(q);
    }).toList();

    final user = _userPoint;
    if (user != null) {
      out.sort((a, b) {
        final da = _geo.as(
          LengthUnit.Meter,
          user,
          a.point,
        );
        final db = _geo.as(
          LengthUnit.Meter,
          user,
          b.point,
        );
        return da.compareTo(db);
      });
    }
    return out;
  }

  String _distanceLabelFor(_MapPlace place) {
    final user = _userPoint;
    if (user == null) return place.distanceKm;
    final meters = BilletterieLocationService.distanceMeters(
      fromLat: user.latitude,
      fromLng: user.longitude,
      toLat: place.point.latitude,
      toLng: place.point.longitude,
    );
    return BilletterieLocationService.formatDistance(meters);
  }

  Future<void> _loadLocation() async {
    final location = await _fastMapLocation();
    if (!mounted) return;
    final moveCamera = !_didInitialCamera;
    _applyUserLocation(location, moveCamera: moveCamera);
    if (moveCamera) _didInitialCamera = true;
    if (_userPoint == null) {
      unawaited(_refineLocationInBackground());
    }
  }

  Future<BilletterieLocationResult> _fastMapLocation() async {
    final cached = BilletterieLocationService.cached;
    if (cached != null) {
      return BilletterieLocationResult.ok(cached);
    }

    final granted = await BilletterieLocationService.hasGrantedPermission();
    if (!granted) {
      return BilletterieLocationResult.fail(BilletterieLocationStatus.denied);
    }

    return BilletterieLocationService.requestAndGetPosition(forceRefresh: false)
        .timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        final again = BilletterieLocationService.cached;
        if (again != null) return BilletterieLocationResult.ok(again);
        return BilletterieLocationResult.fail(BilletterieLocationStatus.error);
      },
    );
  }

  Future<void> _refineLocationInBackground() async {
    final granted = await BilletterieLocationService.hasGrantedPermission();
    if (!granted || !mounted) return;

    final result = await BilletterieLocationService.requestAndGetPosition(
      forceRefresh: false,
    );
    if (!mounted || !result.hasLocation) return;
    _applyUserLocation(result, moveCamera: false);
  }

  void _applyUserLocation(
    BilletterieLocationResult location, {
    required bool moveCamera,
  }) {
    final userLat = location.location?.latitude;
    final userLng = location.location?.longitude;
    final userPoint = (userLat != null && userLng != null)
        ? LatLng(userLat, userLng)
        : null;
    final center = userPoint ?? _abidjan;

    setState(() {
      _userPoint = userPoint ?? _userPoint;
      _center = center;
      _showUserSonar = (_userPoint ?? userPoint) != null;
    });

    if (moveCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(center, userPoint != null ? _myLocationZoom : 12.2);
      });
    }
  }

  void _recenterCamera(LatLng point) {
    setState(() {
      _userPoint = point;
      _center = point;
      _showUserSonar = true;
      _selectedId = null;
    });
    _mapController.move(point, _myLocationZoom);
  }

  Future<void> _goToMyLocation() async {
    if (_recentering) return;
    _recentering = true;
    try {
      final cachedService = BilletterieLocationService.cached;
      final instant = _userPoint ??
          (cachedService != null
              ? LatLng(cachedService.latitude, cachedService.longitude)
              : null);
      if (instant != null) {
        _recenterCamera(instant);
      }

      var result = await BilletterieLocationService.requestAndGetPosition(
        forceRefresh: true,
      );
      if (!mounted) return;

      if (!result.hasLocation) {
        result = await ensureBilletterieLocation(context);
        if (!mounted || !result.hasLocation) return;
      }

      final fresh = LatLng(
        result.location!.latitude,
        result.location!.longitude,
      );
      final previous = _userPoint;
      if (previous == null ||
          _geo.as(LengthUnit.Meter, previous, fresh) > 25) {
        _recenterCamera(fresh);
      } else {
        setState(() {
          _userPoint = fresh;
          _center = fresh;
          _showUserSonar = true;
        });
      }
    } finally {
      _recentering = false;
    }
  }

  void _selectPlace(_MapPlace place) {
    setState(() => _selectedId = place.data.id);
    _mapController.move(place.point, 14);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chrome = _MapChrome.of(context);
    final places = _filtered;
    const sheetH = 220.0;
    final userPoint = _userPoint;
    final navClearance = BilletterieEventBottomNav.layoutHeight(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: chrome.statusStyle,
      child: ColoredBox(
        color: chrome.scaffold,
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 12.2,
                  minZoom: 10,
                  maxZoom: 18,
                  backgroundColor: chrome.mapBg,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: chrome.tileUrl,
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.monpeya.billetterie',
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                  MarkerLayer(
                    markers: [
                      if (_showUserSonar && userPoint != null)
                        Marker(
                          point: userPoint,
                          width: 120,
                          height: 120,
                          alignment: Alignment.center,
                          child: BilletterieUserSonarMarker(color: chrome.accent),
                        ),
                      for (final place in places)
                        Marker(
                          point: place.point,
                          width: 118,
                          height: 96,
                          alignment: Alignment.topCenter,
                          child: _PhotoMarker(
                            chrome: chrome,
                            imageUrl: place.data.imageUrl,
                            label: place.shortLabel,
                            selected: place.data.id == _selectedId,
                            onTap: () {
                              _selectPlace(place);
                              openEventDetails(context, place.data);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: chrome.panel,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: chrome.panelBorder),
                              boxShadow: chrome.isLight
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: chrome.accent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.confirmation_number_rounded,
                                    color: chrome.accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(
                                      color: chrome.fg,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    cursorColor: chrome.accent,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: 'Abidjan, événements…',
                                      hintStyle: TextStyle(
                                        color: chrome.fgMuted,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: chrome.fgMuted,
                                        size: 20,
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: chrome.accent
                                          .withValues(alpha: 0.7),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        chrome.accent.withValues(alpha: 0.28),
                                        const Color(0xFFA78BFA)
                                            .withValues(alpha: 0.28),
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: chrome.accent,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Filtrer',
                                        style: TextStyle(
                                          color: chrome.isLight
                                              ? chrome.fg
                                              : Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final selected = cat.label == _category;
                            final fg = selected
                                ? Colors.white
                                : chrome.chipIdleFg;
                            return Material(
                              color: selected
                                  ? chrome.accent
                                  : chrome.chipIdle,
                              elevation:
                                  chrome.isLight && !selected ? 1 : 0,
                              shadowColor: Colors.black26,
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: selected
                                      ? chrome.accent
                                      : chrome.chipIdleBorder,
                                ),
                              ),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _category = cat.label),
                                customBorder: const StadiumBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cat.icon, size: 15, color: fg),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          color: fg,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: sheetH + navClearance + 12,
              child: Material(
                color: chrome.panel,
                elevation: chrome.isLight ? 2 : 0,
                shadowColor: Colors.black26,
                shape: CircleBorder(
                  side: BorderSide(color: chrome.panelBorder),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _goToMyLocation,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.my_location_rounded,
                      color: chrome.fg,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NearbyFindsSheet(
                chrome: chrome,
                places: places,
                distanceLabelFor: _distanceLabelFor,
                underNavExtent: navClearance,
                onTap: (place) {
                  _selectPlace(place);
                  openEventDetails(context, place.data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoMarker extends StatelessWidget {
  const _PhotoMarker({
    required this.chrome,
    required this.imageUrl,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _MapChrome chrome;
  final String imageUrl;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: selected ? 54 : 46,
            height: selected ? 54 : 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? chrome.accent : chrome.markerRingIdle,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: chrome.isLight ? 0.18 : 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: chrome.accent.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.event,
                    color: chrome.isLight ? chrome.accent : Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chrome.markerLabelBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: chrome.markerLabelBorder),
              boxShadow: chrome.isLight
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chrome.markerLabelFg,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyFindsSheet extends StatelessWidget {
  const _NearbyFindsSheet({
    required this.chrome,
    required this.places,
    required this.distanceLabelFor,
    required this.underNavExtent,
    required this.onTap,
  });

  final _MapChrome chrome;
  final List<_MapPlace> places;
  final String Function(_MapPlace place) distanceLabelFor;
  final double underNavExtent;
  final ValueChanged<_MapPlace> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: chrome.panel,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: chrome.panelBorder),
            boxShadow: chrome.isLight
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: chrome.accent,
                size: 22,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: chrome.fg,
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            fontFamily: 'serif',
                          ),
                          children: [
                            const TextSpan(text: 'À proximité '),
                            TextSpan(
                              text: 'trouvés',
                              style: TextStyle(
                                color: chrome.accent,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${places.length} LIEUX',
                      style: TextStyle(
                        color: chrome.fgMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 158,
                child: places.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun événement dans cette zone',
                          style: TextStyle(color: chrome.fgMuted),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: places.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final place = places[index];
                          return GestureDetector(
                            onTap: () => onTap(place),
                            child: _NearbyCard(
                              chrome: chrome,
                              place: place,
                              distanceLabel: distanceLabelFor(place),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: underNavExtent),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.chrome,
    required this.place,
    required this.distanceLabel,
  });

  final _MapChrome chrome;
  final _MapPlace place;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: chrome.isLight
                ? Border.all(color: chrome.panelBorder)
                : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                place.data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: chrome.isLight
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF1A1A1E),
                  child: Icon(
                    Icons.event,
                    color: chrome.isLight ? chrome.fgMuted : Colors.white54,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    place.tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          place.rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.near_me_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          distanceLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        fontFamily: 'serif',
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
