import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/transport/constants/transport_cities.dart';
import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/features/transport/screens/ticket_details.screen.dart';
import 'package:billetterie/src/features/transport/services/transport_road_router.dart';
import 'package:billetterie/src/features/transport/services/transport_route_graph.dart';
import 'package:billetterie/src/shared/services/billetterie_location.service.dart';
import 'package:billetterie/src/shared/widgets/billetterie_bottom_nav.widget.dart';
import 'package:billetterie/src/shared/widgets/billetterie_location_modal.widget.dart';
import 'package:billetterie/src/shared/widgets/billetterie_user_sonar_marker.widget.dart';

class _RoutePin {
  const _RoutePin({
    required this.ticket,
    required this.fromPoint,
    required this.toPoint,
    required this.fromLabel,
    required this.toLabel,
  });

  final BilletterieTransportTicket ticket;
  final LatLng fromPoint;
  final LatLng toPoint;
  final String fromLabel;
  final String toLabel;

  String get id => ticket.ticketCode ?? ticket.resolvedQrPayload;

  String get title =>
      ticket.title?.trim().isNotEmpty == true
          ? ticket.title!.trim()
          : '$fromLabel → $toLabel';
}

class _ResolvedRoute {
  const _ResolvedRoute({
    required this.points,
    required this.distanceKm,
    required this.durationLabel,
    required this.fromRoads,
  });

  final List<LatLng> points;
  final double distanceKm;
  final String durationLabel;
  final bool fromRoads;

  LatLng get badgePoint =>
      points.isEmpty ? const LatLng(0, 0) : points[points.length ~/ 2];

  LatLng get arrowPoint {
    if (points.isEmpty) return const LatLng(0, 0);
    return points[(points.length * 0.62).floor().clamp(0, points.length - 1)];
  }

  double get arrowBearingDeg {
    if (points.length < 2) return 0;
    final i = (points.length * 0.62).floor().clamp(1, points.length - 1);
    final a = points[i - 1];
    final b = points[i];
    return math.atan2(
          b.longitude - a.longitude,
          b.latitude - a.latitude,
        ) *
        180 /
        math.pi;
  }
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
    required this.badgeIdle,
    required this.badgeIdleBorder,
    required this.badgeFg,
    required this.badgeMuted,
    required this.cardIdle,
    required this.cardIdleBorder,
    required this.statusStyle,
  });

  factory _MapChrome.of(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
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
        badgeIdle: Colors.white.withValues(alpha: 0.95),
        badgeIdleBorder: brand.border,
        badgeFg: brand.text,
        badgeMuted: brand.muted,
        cardIdle: Colors.white.withValues(alpha: 0.92),
        cardIdleBorder: brand.border,
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
      badgeIdle: Colors.black.withValues(alpha: 0.78),
      badgeIdleBorder: Colors.white24,
      badgeFg: Colors.white,
      badgeMuted: Colors.white.withValues(alpha: 0.8),
      cardIdle: Colors.white.withValues(alpha: 0.08),
      cardIdleBorder: Colors.white24,
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
  final Color badgeIdle;
  final Color badgeIdleBorder;
  final Color badgeFg;
  final Color badgeMuted;
  final Color cardIdle;
  final Color cardIdleBorder;
  final SystemUiOverlayStyle statusStyle;
}

/// Map explore for transport — routes + nearby trajets sheet (light/dark).
class TransportMapExploreScreen extends StatefulWidget {
  const TransportMapExploreScreen({
    super.key,
    required this.tickets,
    this.onRefresh,
  });

  final List<BilletterieTransportTicket> tickets;
  final Future<void> Function()? onRefresh;

  @override
  State<TransportMapExploreScreen> createState() =>
      _TransportMapExploreScreenState();
}

class _TransportMapExploreScreenState extends State<TransportMapExploreScreen>
    with AutomaticKeepAliveClientMixin {
  static const _categories = [
    (label: 'Tous', icon: Icons.near_me_rounded),
    (label: 'Bus', icon: Icons.directions_bus_rounded),
    (label: 'Minibus', icon: Icons.airport_shuttle_rounded),
    (label: 'Taxi', icon: Icons.local_taxi_rounded),
    (label: 'Moto', icon: Icons.two_wheeler_rounded),
  ];

  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _geo = Distance();
  final Map<String, _ResolvedRoute> _resolvedById = {};
  int _resolveGen = 0;
  String _category = _categories.first.label;
  String? _selectedId;
  LatLng _center = TransportCities.abidjan;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveRoadPaths();
      _loadLocation();
    });
  }

  @override
  void didUpdateWidget(covariant TransportMapExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.tickets, widget.tickets)) {
      _resolveRoadPaths();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Snap each trajet to Mapbox driving roads. Progressive updates.
  Future<void> _resolveRoadPaths() async {
    final gen = ++_resolveGen;
    final pins = List<_RoutePin>.of(_routes);
    await Future.wait(pins.map((pin) async {
      final road = await TransportRoadRouter.driving(
        from: pin.fromPoint,
        to: pin.toPoint,
      );
      if (!mounted || gen != _resolveGen) return;
      setState(() {
        _resolvedById[pin.id] = _ResolvedRoute(
          points: road.points,
          distanceKm: road.distanceKm,
          durationLabel: road.durationLabel,
          fromRoads: true,
        );
      });
      // Refit once the active trajet snaps onto roads.
      final selectedId = _selectedId ?? (pins.isNotEmpty ? pins.first.id : null);
      if (selectedId == pin.id && road.points.length >= 2) {
        try {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(road.points),
              padding: const EdgeInsets.fromLTRB(56, 170, 56, 250),
              maxZoom: 13.5,
            ),
          );
        } catch (_) {}
      }
    }));
  }

  _ResolvedRoute _geometryOf(_RoutePin route) {
    final cached = _resolvedById[route.id];
    if (cached != null && cached.points.length >= 2) return cached;
    final provisional = TransportRouteGraph.densifySegment(
      route.fromPoint,
      route.toPoint,
    );
    final km = TransportRouteGraph.haversineKm(route.fromPoint, route.toPoint);
    return _ResolvedRoute(
      points: provisional,
      distanceKm: km,
      durationLabel: route.ticket.durationLabel,
      fromRoads: false,
    );
  }

  List<BilletterieTransportTicket> get _source {
    if (widget.tickets.isNotEmpty) return widget.tickets;
    return BilletterieTransportTicket.samples;
  }

  List<_RoutePin> get _routes {
    final out = <_RoutePin>[];
    for (final ticket in _source) {
      final titleParts = ticket.title
          ?.split(RegExp(r'\s*[—\-–]\s*'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final fromName = TransportCities.resolveCityName(ticket.fromCode) ??
          TransportCities.resolveCityName(ticket.fromCity) ??
          (titleParts != null && titleParts.isNotEmpty
              ? TransportCities.resolveCityName(titleParts.first)
              : null);
      final toName = TransportCities.resolveCityName(ticket.toCode) ??
          TransportCities.resolveCityName(ticket.toCity) ??
          (titleParts != null && titleParts.length > 1
              ? TransportCities.resolveCityName(titleParts.last)
              : null);

      final fromPoint =
          fromName != null ? TransportCities.coordinates[fromName] : null;
      final toPoint =
          toName != null ? TransportCities.coordinates[toName] : null;
      if (fromPoint == null || toPoint == null) continue;

      out.add(
        _RoutePin(
          ticket: ticket,
          fromPoint: fromPoint,
          toPoint: toPoint,
          fromLabel: fromName ?? ticket.fromCode,
          toLabel: toName ?? ticket.toCode,
        ),
      );
    }
    return out;
  }

  List<_RoutePin> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final out = _routes.where((r) {
      final type = (r.ticket.vehicleType ?? '').toUpperCase();
      final catOk = _category == 'Tous' ||
          (_category == 'Bus' &&
              type.contains('BUS') &&
              !type.contains('MINI')) ||
          (_category == 'Minibus' && type.contains('MINI')) ||
          (_category == 'Taxi' && type.contains('TAXI')) ||
          (_category == 'Moto' &&
              (type.contains('MOTOR') || type.contains('MOTO')));
      if (!catOk) return false;
      if (q.isEmpty) return true;
      return r.title.toLowerCase().contains(q) ||
          r.fromLabel.toLowerCase().contains(q) ||
          r.toLabel.toLowerCase().contains(q) ||
          r.ticket.fromCode.toLowerCase().contains(q) ||
          r.ticket.toCode.toLowerCase().contains(q) ||
          (r.ticket.place?.toLowerCase().contains(q) ?? false) ||
          r.ticket.vehicleNumber.toLowerCase().contains(q);
    }).toList();

    final user = _userPoint;
    if (user != null) {
      out.sort((a, b) => _nearestEndpointMeters(a, user).compareTo(
            _nearestEndpointMeters(b, user),
          ));
    }
    return out;
  }

  double _nearestEndpointMeters(_RoutePin route, LatLng user) {
    final fromM = _geo.as(LengthUnit.Meter, user, route.fromPoint);
    final toM = _geo.as(LengthUnit.Meter, user, route.toPoint);
    return fromM < toM ? fromM : toM;
  }

  String _userDistanceLabel(_RoutePin route) {
    final user = _userPoint;
    if (user == null) return '';
    return BilletterieLocationService.formatDistance(
      _nearestEndpointMeters(route, user),
    );
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
    final center = userPoint ?? TransportCities.abidjan;

    setState(() {
      _userPoint = userPoint ?? _userPoint;
      _center = center;
      _showUserSonar = (_userPoint ?? userPoint) != null;
    });

    if (moveCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(
          center,
          userPoint != null ? _myLocationZoom : 12.0,
        );
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

  void _selectRoute(_RoutePin route) {
    setState(() => _selectedId = route.id);
    final geo = _geometryOf(route);
    final bounds = LatLngBounds.fromPoints(geo.points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(56, 170, 56, 250),
        maxZoom: 13.5,
      ),
    );
  }

  Future<void> _openTicket(_RoutePin route) async {
    _selectRoute(route);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TicketDetailsScreen(ticket: route.ticket),
      ),
    );
  }

  /// One pin per city label — prefers departure styling when a city is both.
  Map<String, ({LatLng point, String label, bool isDeparture})> _uniqueEndpoints(
    List<_RoutePin> routes,
  ) {
    final out = <String, ({LatLng point, String label, bool isDeparture})>{};
    for (final route in routes) {
      out.putIfAbsent(
        route.fromLabel,
        () => (
          point: route.fromPoint,
          label: route.fromLabel,
          isDeparture: true,
        ),
      );
      out.putIfAbsent(
        route.toLabel,
        () => (
          point: route.toPoint,
          label: route.toLabel,
          isDeparture: false,
        ),
      );
    }
    return out;
  }

  void _openRouteForCity(String city, List<_RoutePin> routes) {
    for (final route in routes) {
      if (route.fromLabel == city || route.toLabel == city) {
        _openTicket(route);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chrome = _MapChrome.of(context);
    final routes = _filtered;
    _RoutePin? selected;
    for (final r in routes) {
      if (r.id == _selectedId) {
        selected = r;
        break;
      }
    }
    selected ??= routes.isNotEmpty ? routes.first : null;
    const sheetH = 220.0;
    final userPoint = _userPoint;
    final navClearance = BilletterieBottomNav.layoutHeight(context);

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
                  initialZoom: 12.0,
                  minZoom: 8,
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
                  // Soft underlay so thin routes stay readable on light tiles.
                  PolylineLayer(
                    polylines: [
                      for (final route in routes)
                        if (route.id != selected?.id)
                          Polyline(
                            points: _geometryOf(route).points,
                            color: chrome.isLight
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.45),
                            strokeWidth: 6,
                          ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final route in routes)
                        if (route.id != selected?.id)
                          Polyline(
                            points: _geometryOf(route).points,
                            color: chrome.accent.withValues(alpha: 0.28),
                            strokeWidth: 3,
                          ),
                    ],
                  ),
                  if (selected != null) ...[
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _geometryOf(selected).points,
                          color: chrome.isLight
                              ? Colors.white
                              : Colors.black.withValues(alpha: 0.55),
                          strokeWidth: 10,
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _geometryOf(selected).points,
                          color: chrome.accent,
                          strokeWidth: 5,
                          borderStrokeWidth: 1.2,
                          borderColor: chrome.accent.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ],
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
                      // Deduped city pins.
                      for (final entry in _uniqueEndpoints(routes).entries)
                        Marker(
                          point: entry.value.point,
                          width: 100,
                          height: 64,
                          alignment: Alignment.topCenter,
                          child: _CityPin(
                            chrome: chrome,
                            label: entry.value.label,
                            isDeparture: entry.value.isDeparture,
                            selected: selected != null &&
                                (selected.fromLabel == entry.value.label ||
                                    selected.toLabel == entry.value.label),
                            onTap: () =>
                                _openRouteForCity(entry.value.label, routes),
                          ),
                        ),
                      // Direction chevron on the active trajet.
                      if (selected != null)
                        Marker(
                          point: _geometryOf(selected).arrowPoint,
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          child: Transform.rotate(
                            angle: _geometryOf(selected).arrowBearingDeg *
                                math.pi /
                                180,
                            child: Container(
                              decoration: BoxDecoration(
                                color: chrome.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: chrome.isLight
                                      ? Colors.white
                                      : Colors.black26,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.22),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      // Price / duration badge — active route first, others quieter.
                      for (final route in routes)
                        Marker(
                          point: _geometryOf(route).badgePoint,
                          width: 118,
                          height: 46,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: route.id == selected?.id ? 1 : 0.55,
                            child: _RouteBadge(
                              chrome: chrome,
                              label:
                                  '${route.ticket.price} ${route.ticket.currency}',
                              duration:
                                  '${_geometryOf(route).distanceKm.toStringAsFixed(1)} km · ${_geometryOf(route).durationLabel}',
                              selected: route.id == selected?.id,
                              onTap: () => _openTicket(route),
                            ),
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
                                    Icons.directions_bus_rounded,
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
                                      hintText: 'Cocody, Plateau, trajets…',
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
                                if (widget.onRefresh != null)
                                  IconButton(
                                    onPressed: () async {
                                      await widget.onRefresh?.call();
                                      if (mounted) setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.refresh_rounded,
                                      color: chrome.accent,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < _categories.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: _TypeChip(
                                label: _categories[i].label,
                                icon: _categories[i].icon,
                                selected: _categories[i].label == _category,
                                chrome: chrome,
                                onTap: () => setState(
                                  () => _category = _categories[i].label,
                                ),
                              ),
                            ),
                          ],
                        ],
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
              child: _NearbyRoutesSheet(
                chrome: chrome,
                routes: routes,
                selectedId: selected?.id,
                geometryOf: _geometryOf,
                userDistanceLabel: _userDistanceLabel,
                underNavExtent: navClearance,
                onTap: _selectRoute,
                onOpen: _openTicket,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.chrome,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final _MapChrome chrome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : chrome.chipIdleFg;
    return Material(
      color: selected ? chrome.accent : chrome.chipIdle,
      elevation: chrome.isLight && !selected ? 1 : 0,
      shadowColor: Colors.black26,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? chrome.accent : chrome.chipIdleBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityPin extends StatelessWidget {
  const _CityPin({
    required this.chrome,
    required this.label,
    required this.isDeparture,
    required this.selected,
    required this.onTap,
  });

  final _MapChrome chrome;
  final String label;
  final bool isDeparture;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dot = selected ? 30.0 : 26.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDeparture ? chrome.accent : Colors.white,
              border: Border.all(
                color: selected
                    ? chrome.accent
                    : (chrome.isLight ? chrome.panelBorder : Colors.white70),
                width: selected ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: chrome.isLight ? 0.16 : 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              isDeparture ? Icons.trip_origin_rounded : Icons.flag_rounded,
              size: 13,
              color: isDeparture ? Colors.white : chrome.accent,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            constraints: const BoxConstraints(maxWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: chrome.badgeIdle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? chrome.accent : chrome.badgeIdleBorder,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: chrome.badgeFg,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge({
    required this.chrome,
    required this.label,
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final _MapChrome chrome;
  final String label;
  final String duration;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : chrome.badgeFg;
    final muted = selected
        ? Colors.white.withValues(alpha: 0.85)
        : chrome.badgeMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? chrome.accent : chrome.badgeIdle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? chrome.accent : chrome.badgeIdleBorder,
          ),
          boxShadow: chrome.isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            Text(
              duration,
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyRoutesSheet extends StatelessWidget {
  const _NearbyRoutesSheet({
    required this.chrome,
    required this.routes,
    required this.selectedId,
    required this.geometryOf,
    required this.userDistanceLabel,
    required this.underNavExtent,
    required this.onTap,
    required this.onOpen,
  });

  final _MapChrome chrome;
  final List<_RoutePin> routes;
  final String? selectedId;
  final _ResolvedRoute Function(_RoutePin route) geometryOf;
  final String Function(_RoutePin route) userDistanceLabel;
  final double underNavExtent;
  final ValueChanged<_RoutePin> onTap;
  final ValueChanged<_RoutePin> onOpen;

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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: chrome.fg,
                                fontWeight: FontWeight.w700,
                              ),
                          children: [
                            const TextSpan(text: 'Trajets '),
                            TextSpan(
                              text: 'à proximité',
                              style: TextStyle(
                                color: chrome.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${routes.length} LIGNES',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: chrome.fgMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 158,
                child: routes.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun trajet dans cette zone',
                          style: TextStyle(color: chrome.fgMuted),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: routes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          final selected = route.id == selectedId;
                          return GestureDetector(
                            onTap: () {
                              if (selected) {
                                onOpen(route);
                              } else {
                                onTap(route);
                              }
                            },
                            child: _NearbyRouteCard(
                              chrome: chrome,
                              route: route,
                              geometry: geometryOf(route),
                              userDistance: userDistanceLabel(route),
                              selected: selected,
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

class _NearbyRouteCard extends StatelessWidget {
  const _NearbyRouteCard({
    required this.chrome,
    required this.route,
    required this.geometry,
    required this.userDistance,
    required this.selected,
  });

  final _MapChrome chrome;
  final _RoutePin route;
  final _ResolvedRoute geometry;
  final String userDistance;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ticket = route.ticket;
    final tagBg = chrome.isLight
        ? chrome.accent.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.12);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 188,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? chrome.accent.withValues(alpha: chrome.isLight ? 0.12 : 0.22)
            : chrome.cardIdle,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? chrome.accent : chrome.cardIdleBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  (ticket.vehicleType ?? 'TRAJET').toUpperCase(),
                  style: TextStyle(
                    color: chrome.isLight ? chrome.accent : chrome.fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule_rounded, color: chrome.accent, size: 14),
              const SizedBox(width: 4),
              Text(
                geometry.durationLabel,
                style: TextStyle(
                  color: chrome.fg.withValues(alpha: chrome.isLight ? 0.8 : 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            route.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: chrome.fg,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userDistance.isNotEmpty
                ? '$userDistance · ${geometry.distanceKm.toStringAsFixed(1)} km · ${ticket.fromTime} → ${ticket.toTime}'
                : '${geometry.distanceKm.toStringAsFixed(1)} km · ${ticket.fromTime} → ${ticket.toTime}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: chrome.fgMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${ticket.price} ${ticket.currency}',
            style: TextStyle(
              color: chrome.accent,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
