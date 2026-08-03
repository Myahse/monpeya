import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'package:billetterie/src/features/transport/constants/transport_cities.dart';

/// Undirected road graph over [TransportCities] + Dijkstra shortest path.
///
/// Weights are great-circle kilometres between linked communes / villes.
abstract final class TransportRouteGraph {
  /// Curated adjacencies (Abidjan communes + national corridors).
  static const Map<String, List<String>> _neighbors = {
    // --- Abidjan metro ---
    'Plateau': ['Adjamé', 'Cocody', 'Treichville', 'Marcory', 'Yopougon'],
    'Adjamé': ['Plateau', 'Abobo', 'Cocody', 'Yopougon'],
    'Cocody': ['Plateau', 'Adjamé', 'Bingerville', 'Marcory', 'Abobo'],
    'Treichville': ['Plateau', 'Marcory', 'Port-Bouët', 'Koumassi'],
    'Marcory': ['Treichville', 'Plateau', 'Cocody', 'Koumassi'],
    'Koumassi': ['Marcory', 'Treichville', 'Port-Bouët'],
    'Port-Bouët': ['Treichville', 'Koumassi', 'Grand-Bassam'],
    'Yopougon': ['Plateau', 'Adjamé', 'Songon', 'Abobo'],
    'Abobo': ['Adjamé', 'Anyama', 'Cocody', 'Yopougon'],
    'Bingerville': ['Cocody', 'Grand-Bassam'],
    'Anyama': ['Abobo', 'Agboville'],
    'Songon': ['Yopougon', 'Dabou'],
    'Abidjan': ['Plateau', 'Adjamé', 'Cocody', 'Yopougon'],
    'Grand-Bassam': ['Port-Bouët', 'Bingerville', 'Bonoua'],

    // --- National corridors (simplified) ---
    'Agboville': ['Anyama', 'Abengourou', 'Divo', 'Yamoussoukro'],
    'Abengourou': ['Agboville', 'Bondoukou'],
    'Bondoukou': ['Abengourou'],
    'Divo': ['Agboville', 'Gagnoa', 'Yamoussoukro', 'San-Pédro'],
    'Gagnoa': ['Divo', 'Daloa', 'Soubré'],
    'Yamoussoukro': ['Agboville', 'Divo', 'Bouaké', 'Daloa'],
    'Bouaké': ['Yamoussoukro', 'Korhogo', 'Abengourou'],
    'Korhogo': ['Bouaké', 'Ferkessédougou', 'Odienné'],
    'Ferkessédougou': ['Korhogo'],
    'Daloa': ['Yamoussoukro', 'Gagnoa', 'Issia', 'Séguéla', 'Man'],
    'Issia': ['Daloa', 'Soubré'],
    'Soubré': ['Issia', 'Gagnoa', 'San-Pédro'],
    'San-Pédro': ['Soubré', 'Divo'],
    'Séguéla': ['Daloa', 'Man', 'Odienné'],
    'Man': ['Daloa', 'Séguéla', 'Odienné'],
    'Odienné': ['Man', 'Séguéla', 'Korhogo'],
  };

  /// Extra stubs referenced above but not in [TransportCities.all] — ignored
  /// when missing from coordinates.
  static const _optional = {'Dabou', 'Bonoua'};

  static Map<String, List<({String to, double km})>>? _cache;

  static Map<String, List<({String to, double km})>> get _graph {
    final cached = _cache;
    if (cached != null) return cached;

    final g = <String, List<({String to, double km})>>{};

    void link(String a, String b) {
      final pa = TransportCities.coordinates[a];
      final pb = TransportCities.coordinates[b];
      if (pa == null || pb == null) return;
      final km = haversineKm(pa, pb);
      g.putIfAbsent(a, () => []).add((to: b, km: km));
      g.putIfAbsent(b, () => []).add((to: a, km: km));
    }

    for (final entry in _neighbors.entries) {
      for (final n in entry.value) {
        if (_optional.contains(n) &&
            !TransportCities.coordinates.containsKey(n)) {
          continue;
        }
        link(entry.key, n);
      }
    }

    // Ensure every known city is a node (isolated if unlinked).
    for (final city in TransportCities.coordinates.keys) {
      g.putIfAbsent(city, () => []);
    }

    return _cache = g;
  }

  /// Shortest path as ordered city names (inclusive). Empty if unreachable.
  static List<String> shortestCityPath(String from, String to) {
    if (from == to) return [from];
    final graph = _graph;
    if (!graph.containsKey(from) || !graph.containsKey(to)) return [];

    final dist = <String, double>{for (final n in graph.keys) n: double.infinity};
    final prev = <String, String?>{};
    final visited = <String>{};
    dist[from] = 0;

    while (true) {
      String? u;
      var best = double.infinity;
      for (final n in graph.keys) {
        if (visited.contains(n)) continue;
        final d = dist[n]!;
        if (d < best) {
          best = d;
          u = n;
        }
      }
      if (u == null || best == double.infinity) break;
      if (u == to) break;
      visited.add(u);

      for (final edge in graph[u]!) {
        if (visited.contains(edge.to)) continue;
        final alt = best + edge.km;
        if (alt < dist[edge.to]!) {
          dist[edge.to] = alt;
          prev[edge.to] = u;
        }
      }
    }

    if (dist[to] == double.infinity) return [];

    final path = <String>[];
    String? cur = to;
    while (cur != null) {
      path.add(cur);
      if (cur == from) break;
      cur = prev[cur];
    }
    return path.reversed.toList();
  }

  /// Map polyline for [from] → [to] via Dijkstra waypoints.
  ///
  /// Falls back to the direct segment when no graph path exists.
  static List<LatLng> pathPoints({
    required String from,
    required String to,
    LatLng? fromPoint,
    LatLng? toPoint,
  }) {
    final a = fromPoint ?? TransportCities.coordinates[from];
    final b = toPoint ?? TransportCities.coordinates[to];
    if (a == null || b == null) {
      return [
        if (a != null) a,
        if (b != null) b,
      ];
    }

    final cities = shortestCityPath(from, to);
    if (cities.length < 2) {
      return densifySegment(a, b);
    }

    final waypoints = <LatLng>[];
    for (final city in cities) {
      final p = TransportCities.coordinates[city];
      if (p != null) waypoints.add(p);
    }
    if (waypoints.isEmpty) return densifySegment(a, b);

    // Snap ends to the ticket endpoints (same city center is fine).
    waypoints[0] = a;
    waypoints[waypoints.length - 1] = b;

    final out = <LatLng>[waypoints.first];
    for (var i = 0; i < waypoints.length - 1; i++) {
      final densified = densifySegment(waypoints[i], waypoints[i + 1]);
      out.addAll(densified.skip(1));
    }
    return out;
  }

  /// Intermediate cities on the Dijkstra path (excluding ends).
  static List<String> viaCities(String from, String to) {
    final path = shortestCityPath(from, to);
    if (path.length <= 2) return const [];
    return path.sublist(1, path.length - 1);
  }

  static double haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final la1 = _rad(a.latitude);
    final la2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  /// Even samples along a segment so the stroke looks continuous when zoomed.
  static List<LatLng> densifySegment(LatLng a, LatLng b, {int minPoints = 8}) {
    final km = haversineKm(a, b);
    final steps = math.max(minPoints, (km * 2).ceil()).clamp(2, 48);
    final points = <LatLng>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(
        LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ),
      );
    }
    return points;
  }
}
