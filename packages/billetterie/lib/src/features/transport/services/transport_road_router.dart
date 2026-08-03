import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:billetterie/src/features/transport/services/transport_route_graph.dart';
import 'package:billetterie/src/shared/config/billetterie_env.registry.dart';

/// Result of a driving route that follows the road network.
class TransportRoadRoute {
  const TransportRoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  double get distanceKm => distanceMeters / 1000.0;

  String get durationLabel {
    final mins = (durationSeconds / 60).round().clamp(1, 9999);
    if (mins < 60) return '${mins}min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

/// Road-following router via [Mapbox Directions API](https://docs.mapbox.com/api/navigation/directions/).
///
/// Requires `MAPBOX_ACCESS_TOKEN` in `app/.env` (see BilletterieEnvRegistry).
/// Falls back to a densified straight segment if the token is missing or the
/// network call fails.
abstract final class TransportRoadRouter {
  static const _base =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  static final Map<String, Future<TransportRoadRoute>> _inflight = {};
  static final Map<String, TransportRoadRoute> _cache = {};

  static String? get _accessToken {
    final fromEnv = BilletterieEnvRegistry.mapboxAccessToken;
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    const fromDefine = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    return fromDefine.isEmpty ? null : fromDefine;
  }

  static String _key(LatLng from, LatLng to, List<LatLng> vias) {
    String fmt(LatLng p) =>
        '${p.longitude.toStringAsFixed(5)},${p.latitude.toStringAsFixed(5)}';
    final mid = vias.map(fmt).join(';');
    return '${fmt(from)}>${mid.isEmpty ? '' : '$mid>'}${fmt(to)}';
  }

  /// Driving path [from] → optional [vias] → [to], following Mapbox roads.
  static Future<TransportRoadRoute> driving({
    required LatLng from,
    required LatLng to,
    List<LatLng> vias = const [],
  }) {
    final key = _key(from, to, vias);
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    return _inflight.putIfAbsent(key, () async {
      try {
        final route = await _fetchMapbox(from: from, to: to, vias: vias);
        _cache[key] = route;
        return route;
      } catch (_) {
        final fallback = _fallback(from, to);
        _cache[key] = fallback;
        return fallback;
      } finally {
        _inflight.remove(key);
      }
    });
  }

  static Future<TransportRoadRoute> _fetchMapbox({
    required LatLng from,
    required LatLng to,
    required List<LatLng> vias,
  }) async {
    final token = _accessToken;
    if (token == null) {
      throw StateError('MAPBOX_ACCESS_TOKEN missing');
    }

    final coords = <LatLng>[from, ...vias, to];
    final path = coords
        .map((p) =>
            '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
        .join(';');

    final uri = Uri.parse('$_base/$path').replace(
      queryParameters: {
        'geometries': 'geojson',
        'overview': 'full',
        'steps': 'false',
        'alternatives': 'false',
        'access_token': token,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Mapbox HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Mapbox: invalid JSON');
    }
    final code = decoded['code']?.toString();
    if (code != null && code != 'Ok') {
      throw StateError('Mapbox: $code');
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      throw StateError('Mapbox: no routes');
    }
    final route = routes.first;
    if (route is! Map) throw StateError('Mapbox: bad route');

    final geometry = route['geometry'];
    if (geometry is! Map) throw StateError('Mapbox: no geometry');
    final rawCoords = geometry['coordinates'];
    if (rawCoords is! List || rawCoords.isEmpty) {
      throw StateError('Mapbox: empty coordinates');
    }

    final points = <LatLng>[];
    for (final c in rawCoords) {
      if (c is! List || c.length < 2) continue;
      final lng = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      points.add(LatLng(lat, lng));
    }
    if (points.length < 2) throw StateError('Mapbox: too few points');

    final distance = (route['distance'] as num?)?.toDouble() ?? 0;
    final duration = (route['duration'] as num?)?.toDouble() ?? 0;

    return TransportRoadRoute(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  static TransportRoadRoute _fallback(LatLng from, LatLng to) {
    final points = TransportRouteGraph.densifySegment(from, to);
    final km = TransportRouteGraph.haversineKm(from, to);
    return TransportRoadRoute(
      points: points,
      distanceMeters: km * 1000,
      durationSeconds: (km / 25) * 3600, // ~25 km/h urban guess
    );
  }

  static void clearCache() {
    _cache.clear();
    _inflight.clear();
  }
}
