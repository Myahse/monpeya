import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';
import 'package:immo/src/features/rental/services/rental_location.service.dart';
import 'package:immo/src/features/rental/widgets/rental_location_modal.widget.dart';

class _MapPlace {
  const _MapPlace({
    required this.property,
    required this.shortLabel,
    required this.tag,
    required this.rating,
    required this.distanceLabel,
    required this.point,
  });

  final RentalProperty property;
  final String shortLabel;
  final String tag;
  final String rating;
  final String distanceLabel;
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
    final brand = ImmoBrand.rentalOf(context);
    final isLight =
        MediaQuery.platformBrightnessOf(context) == Brightness.light;
    final accent = brand.primary;

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

/// Carte tab — Billetterie-style map explore for rental properties.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.onPropertySelect});

  final ValueChanged<RentalProperty>? onPropertySelect;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const _abidjan = LatLng(5.3364, -4.0267);
  static const _myLocationZoom = 15.5;
  static final _geo = Distance();

  static const _categories = [
    (label: 'Tous', icon: Icons.near_me_rounded),
    (label: 'Appartement', icon: Icons.apartment_rounded),
    (label: 'Maison', icon: Icons.home_rounded),
    (label: 'Villa', icon: Icons.villa_rounded),
    (label: 'Studio', icon: Icons.meeting_room_rounded),
  ];

  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  AnimationController? _cameraAnim;

  List<_MapPlace> _places = const [];
  // Full-screen spinner only on forced retry with empty data.
  bool _loading = false;
  // Soft chip while listings catch up; map stays interactive.
  bool _listingsLoading = true;
  bool _didInitialCamera = false;
  String? _error;
  String _category = _categories.first.label;
  String? _selectedId;
  LatLng _center = _abidjan;
  LatLng? _userPoint;
  bool _showUserSonar = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _hydrateFromCache() {
    final cached = RentalDataCache.instance.available;
    final loc = RentalLocationService.cached;
    if (cached == null || cached.isEmpty) return;

    final location = loc != null
        ? RentalLocationResult.ok(loc)
        : RentalLocationResult.fail(RentalLocationStatus.error);
    _applyMapData(
      items: cached,
      location: location,
      moveCamera: false,
      notify: false,
    );
    _listingsLoading = false;
  }

  @override
  void dispose() {
    _cameraAnim?.dispose();
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && _places.isNotEmpty) {
      // Already painted — stay put. Pull-to-refresh / retry uses forceRefresh.
      return;
    }

    final session = RentalSessionScope.of(context);
    if (_places.isEmpty) {
      setState(() {
        // Keep the map visible; only block the whole screen on explicit retry.
        _loading = forceRefresh;
        _listingsLoading = true;
        _error = null;
      });
    }

    try {
      final itemsFuture = (session.isBusiness &&
              !session.guestMode &&
              session.userId != null &&
              session.userId!.isNotEmpty)
          ? session.api.properties
              .fetchMyProperties(ownerUserId: session.userId)
          : session.api.properties.fetchAvailableProperties(
              forceRefresh: forceRefresh,
            );

      // GPS in parallel — do not block markers on it.
      final locationFuture = _fastMapLocation();

      final items = await itemsFuture;
      if (!mounted) return;

      // Paint markers immediately with cached GPS (or Abidjan fallback).
      final cachedLoc = RentalLocationService.cached;
      final quickLocation = cachedLoc != null
          ? RentalLocationResult.ok(cachedLoc)
          : RentalLocationResult.fail(RentalLocationStatus.error);
      final moveCamera = !_didInitialCamera;
      _applyMapData(
        items: items,
        location: quickLocation,
        moveCamera: moveCamera,
      );
      if (moveCamera) _didInitialCamera = true;

      final location = await locationFuture;
      if (!mounted) return;
      if (location.hasLocation) {
        _applyMapData(
          items: items,
          location: location,
          moveCamera: _userPoint == null,
        );
        if (_userPoint == null) _didInitialCamera = true;
      }

      // Only chase a fresher GPS once when we still have no user pin.
      if (_userPoint == null) {
        unawaited(_refineLocationInBackground(items));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _listingsLoading = false;
      });
    }
  }

  /// Cache / last-known only — must stay under a couple of seconds.
  Future<RentalLocationResult> _fastMapLocation() async {
    final cached = RentalLocationService.cached;
    if (cached != null) return RentalLocationResult.ok(cached);

    final granted = await RentalLocationService.hasGrantedPermission();
    if (!granted) {
      return RentalLocationResult.fail(RentalLocationStatus.denied);
    }

    return RentalLocationService.requestAndGetPosition(forceRefresh: false)
        .timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        final again = RentalLocationService.cached;
        if (again != null) return RentalLocationResult.ok(again);
        return RentalLocationResult.fail(RentalLocationStatus.error);
      },
    );
  }

  Future<void> _refineLocationInBackground(List<RentalProperty> items) async {
    final granted = await RentalLocationService.hasGrantedPermission();
    if (!granted || !mounted) return;

    // Soft refresh — do not force a new GPS fix if cache is still warm.
    final result = await RentalLocationService.requestAndGetPosition(
      forceRefresh: false,
    );
    if (!mounted || !result.hasLocation) return;
    _applyMapData(items: items, location: result, moveCamera: false);
  }

  void _applyMapData({
    required List<RentalProperty> items,
    required RentalLocationResult location,
    bool moveCamera = false,
    bool notify = true,
  }) {
    final userLat = location.location?.latitude;
    final userLng = location.location?.longitude;
    final userPoint = (userLat != null && userLng != null)
        ? LatLng(userLat, userLng)
        : null;
    final center = userPoint ?? _abidjan;

    final places = <_MapPlace>[];
    for (final p in items) {
      final lat = p.latitude;
      final lng = p.longitude;
      if (lat == null || lng == null) continue;

      String distanceLabel = '—';
      if (userLat != null && userLng != null) {
        final m = RentalLocationService.distanceMeters(
          fromLat: userLat,
          fromLng: userLng,
          toLat: lat,
          toLng: lng,
        );
        distanceLabel = m < 1000
            ? '${m.round()} m'
            : '${(m / 1000).toStringAsFixed(1)} km';
      }

      final city = p.city.trim();
      final short = city.isNotEmpty
          ? city
          : (p.address.trim().isEmpty
              ? p.title
              : p.address.split(',').first.trim());

      final type = p.propertyType.trim();
      final tag =
          type.isEmpty || type == '—' ? 'BIEN' : type.toUpperCase();

      final rating = p.rating > 0 ? p.rating.toStringAsFixed(1) : '—';

      places.add(
        _MapPlace(
          property: p,
          shortLabel: short,
          tag: tag,
          rating: rating,
          distanceLabel: distanceLabel,
          point: LatLng(lat, lng),
        ),
      );
    }

    void apply() {
      _places = places;
      if (moveCamera) _center = center;
      _userPoint = userPoint ?? _userPoint;
      _showUserSonar = (_userPoint ?? userPoint) != null;
      _loading = false;
      _listingsLoading = false;
      _error = null;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }

    if (moveCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(center, 13);
        } catch (_) {}
      });
    }
  }

  List<_MapPlace> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _places.where((p) {
      final type = p.property.propertyType.toLowerCase();
      final catOk = _category == 'Tous' ||
          type.contains(_category.toLowerCase()) ||
          p.tag.toLowerCase().contains(_category.toLowerCase());
      if (!catOk) return false;
      if (q.isEmpty) return true;
      return p.property.title.toLowerCase().contains(q) ||
          p.shortLabel.toLowerCase().contains(q) ||
          p.property.address.toLowerCase().contains(q) ||
          p.property.city.toLowerCase().contains(q);
    }).toList();
  }

  void _selectPlace(_MapPlace place) {
    setState(() => _selectedId = place.property.id);
    unawaited(_animateCameraTo(place.point, zoom: 15));
  }

  bool _recentering = false;

  Future<void> _animateCameraTo(
    LatLng dest, {
    double zoom = _myLocationZoom,
    Duration duration = const Duration(milliseconds: 700),
  }) async {
    LatLng begin;
    double beginZoom;
    try {
      begin = _mapController.camera.center;
      beginZoom = _mapController.camera.zoom;
    } catch (_) {
      _mapController.move(dest, zoom);
      return;
    }

    final meters = _geo.as(LengthUnit.Meter, begin, dest);
    // Already on target: soft zoom pulse so the tap still feels responsive.
    if (meters < 18 && (beginZoom - zoom).abs() < 0.12) {
      await _runCameraTween(
        begin: begin,
        end: dest,
        beginZoom: beginZoom,
        endZoom: zoom - 0.55,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      await _runCameraTween(
        begin: dest,
        end: dest,
        beginZoom: zoom - 0.55,
        endZoom: zoom,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
      );
      return;
    }

    // Longer travels get a slightly longer flight.
    final flight = meters > 2500
        ? const Duration(milliseconds: 950)
        : duration;

    await _runCameraTween(
      begin: begin,
      end: dest,
      beginZoom: beginZoom,
      endZoom: zoom,
      duration: flight,
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _runCameraTween({
    required LatLng begin,
    required LatLng end,
    required double beginZoom,
    required double endZoom,
    required Duration duration,
    required Curve curve,
  }) async {
    _cameraAnim?.stop();
    _cameraAnim?.dispose();

    final controller = AnimationController(vsync: this, duration: duration);
    _cameraAnim = controller;
    final curved = CurvedAnimation(parent: controller, curve: curve);
    final latTween = Tween<double>(begin: begin.latitude, end: end.latitude);
    final lngTween = Tween<double>(begin: begin.longitude, end: end.longitude);
    final zoomTween = Tween<double>(begin: beginZoom, end: endZoom);

    void tick() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(curved), lngTween.evaluate(curved)),
        zoomTween.evaluate(curved),
      );
    }

    controller.addListener(tick);
    try {
      await controller.forward();
    } finally {
      controller.removeListener(tick);
      curved.dispose();
      if (identical(_cameraAnim, controller)) {
        _cameraAnim = null;
        controller.dispose();
      }
    }
  }

  void _recenterCamera(LatLng point) {
    setState(() {
      _userPoint = point;
      _center = point;
      _showUserSonar = true;
      _selectedId = null;
    });
    unawaited(_animateCameraTo(point));
  }

  Future<void> _goToMyLocation() async {
    if (_recentering) return;
    _recentering = true;
    try {
      // Instant feedback from last known point (map marker or service cache).
      final cachedService = RentalLocationService.cached;
      final instant = _userPoint ??
          (cachedService != null
              ? LatLng(cachedService.latitude, cachedService.longitude)
              : null);
      if (instant != null) {
        _recenterCamera(instant);
      }

      // Refresh GPS (no permission modal when already granted).
      var result = await RentalLocationService.requestAndGetPosition(
        forceRefresh: true,
      );
      if (!mounted) return;

      if (!result.hasLocation) {
        result = await ensureRentalLocation(context);
        if (!mounted || !result.hasLocation) return;
      }

      final fresh = LatLng(
        result.location!.latitude,
        result.location!.longitude,
      );
      // Skip a second flight when GPS barely moved.
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chrome = _MapChrome.of(context);
    final places = _filtered;
    const sheetH = 220.0;
    final userPoint = _userPoint;
    final navClearance = RentalBottomNavigation.layoutHeight(context);

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
                  initialZoom: 13,
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
                    userAgentPackageName: 'com.monpeya.immo',
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
                          child: _UserSonarMarker(color: chrome.accent),
                        ),
                      for (final place in places)
                        Marker(
                          point: place.point,
                          width: 118,
                          height: 96,
                          alignment: Alignment.topCenter,
                          child: _PhotoMarker(
                            chrome: chrome,
                            imageUrl: place.property.imageUrl,
                            label: place.shortLabel,
                            selected: place.property.id == _selectedId,
                            onTap: () {
                              _selectPlace(place);
                              widget.onPropertySelect?.call(place.property);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              )
            else if (_listingsLoading && _places.isEmpty)
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + 72,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: chrome.panel,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: chrome.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chargement des biens…',
                            style: TextStyle(
                              color: chrome.fg,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_error != null && _places.isEmpty)
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: chrome.fg),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _load(forceRefresh: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: chrome.accent,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
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
                                    Icons.home_work_outlined,
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
                                      hintText: 'Abidjan, biens…',
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
                                      color:
                                          chrome.accent.withValues(alpha: 0.7),
                                    ),
                                    color:
                                        chrome.accent.withValues(alpha: 0.18),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
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
                            final fg =
                                selected ? Colors.white : chrome.chipIdleFg;
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
                      color: _showUserSonar ? chrome.accent : chrome.fg,
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
                // Panel fills to screen bottom; cards stay above the nav pill.
                underNavExtent: navClearance,
                onTap: (place) {
                  _selectPlace(place);
                  widget.onPropertySelect?.call(place.property);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSonarMarker extends StatefulWidget {
  const _UserSonarMarker({required this.color});

  final Color color;

  @override
  State<_UserSonarMarker> createState() => _UserSonarMarkerState();
}

class _UserSonarMarkerState extends State<_UserSonarMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final phase in const [0.0, 0.45])
                _sonarRing(t, phase),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sonarRing(double t, double phase) {
    final raw = (t + phase) % 1.0;
    final scale = 0.35 + raw * 0.9;
    final opacity = (1.0 - raw).clamp(0.0, 1.0) * 0.55;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: opacity),
            width: 2.2,
          ),
          color: widget.color.withValues(alpha: opacity * 0.18),
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
  final String? imageUrl;
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
              child: imageUrl == null || imageUrl!.isEmpty
                  ? ColoredBox(
                      color: chrome.accent.withValues(alpha: 0.3),
                      child: Icon(
                        Icons.home_work_outlined,
                        color: chrome.isLight ? chrome.accent : Colors.white,
                        size: 18,
                      ),
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      // Decode near display size — much faster marker paint.
                      cacheWidth: (54 *
                              MediaQuery.devicePixelRatioOf(context))
                          .round(),
                      cacheHeight: (54 *
                              MediaQuery.devicePixelRatioOf(context))
                          .round(),
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: chrome.accent.withValues(alpha: 0.3),
                        child: Icon(
                          Icons.home_work_outlined,
                          color:
                              chrome.isLight ? chrome.accent : Colors.white,
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
    required this.underNavExtent,
    required this.onTap,
  });

  final _MapChrome chrome;
  final List<_MapPlace> places;
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
                          style: GoogleFonts.urbanist(
                            color: chrome.fg,
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                          ),
                          children: [
                            const TextSpan(text: 'À proximité '),
                            TextSpan(
                              text: 'trouvés',
                              style: GoogleFonts.urbanist(
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
                      '${places.length} BIENS',
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
                          'Aucun bien avec localisation',
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
                            ),
                          );
                        },
                      ),
              ),
              // Same panel color continues under the floating nav.
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
  });

  final _MapChrome chrome;
  final _MapPlace place;

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.property.imageUrl;
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
              if (imageUrl == null || imageUrl.isEmpty)
                ColoredBox(
                  color: chrome.isLight
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF1A1A1E),
                  child: Icon(
                    Icons.home_work_outlined,
                    color: chrome.isLight ? chrome.fgMuted : Colors.white54,
                  ),
                )
              else
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: chrome.isLight
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1A1A1E),
                    child: Icon(
                      Icons.home_work_outlined,
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
                          place.distanceLabel,
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
                      place.property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
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
