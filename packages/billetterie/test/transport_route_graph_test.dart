import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:billetterie/src/features/transport/services/transport_route_graph.dart';

void main() {
  group('TransportRouteGraph Dijkstra', () {
    test('finds a short Abidjan commune path', () {
      final path =
          TransportRouteGraph.shortestCityPath('Cocody', 'Treichville');
      expect(path.first, 'Cocody');
      expect(path.last, 'Treichville');
      expect(path.length, greaterThanOrEqualTo(2));
      // Should not jump outside Abidjan for a local trip.
      expect(path, isNot(contains('Bouaké')));
    });

    test('returns empty for unknown cities', () {
      expect(
        TransportRouteGraph.shortestCityPath('Cocody', 'Atlantis'),
        isEmpty,
      );
    });

    test('pathPoints densifies the Dijkstra polyline', () {
      final points = TransportRouteGraph.pathPoints(
        from: 'Plateau',
        to: 'Yopougon',
        fromPoint: const LatLng(5.3260, -4.0200),
        toPoint: const LatLng(5.3360, -4.0850),
      );
      expect(points.length, greaterThan(2));
      expect(points.first.latitude, closeTo(5.3260, 0.0001));
      expect(points.last.longitude, closeTo(-4.0850, 0.0001));
    });

    test('haversine is symmetric and positive', () {
      const a = LatLng(5.36, -3.98);
      const b = LatLng(5.30, -4.00);
      final ab = TransportRouteGraph.haversineKm(a, b);
      final ba = TransportRouteGraph.haversineKm(b, a);
      expect(ab, greaterThan(0));
      expect(ab, closeTo(ba, 1e-9));
    });
  });
}
