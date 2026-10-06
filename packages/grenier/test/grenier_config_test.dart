import 'package:flutter_test/flutter_test.dart';

import 'package:grenier/grenier.dart';

void main() {
  group('GrenierModuleKeys', () {
    test('recognises current and legacy keys', () {
      expect(GrenierModuleKeys.isGrenierKey('Grenier'), isTrue);
      expect(GrenierModuleKeys.isGrenierKey('mon_grenier'), isTrue);
      expect(GrenierModuleKeys.isGrenierKey('immo'), isFalse);
      expect(GrenierModuleKeys.isGrenierKey(null), isFalse);
    });
  });

  group('GrenierApiConfig', () {
    tearDown(() {
      GrenierEnvRegistry.baseUrl = null;
      GrenierEnvRegistry.wsUrl = null;
    });

    test('strips trailing slashes from the runtime base URL', () {
      GrenierEnvRegistry.apply(baseUrl: 'https://grenier.example.com//');
      expect(GrenierApiConfig.baseUrl, 'https://grenier.example.com');
    });

    test('derives a secure websocket URL from an https base URL', () {
      GrenierEnvRegistry.apply(baseUrl: 'https://grenier.example.com:8443');
      expect(
        GrenierApiConfig.wsUrl,
        'wss://grenier.example.com:8443/ws/realtime',
      );
    });

    test('prefers an explicit websocket URL', () {
      GrenierEnvRegistry.apply(
        baseUrl: 'http://10.0.2.2:8083',
        wsUrl: 'ws://lan:9000/ws',
      );
      expect(GrenierApiConfig.wsUrl, 'ws://lan:9000/ws');
    });
  });

  group('GrenierProduit', () {
    test('parses JSON and formats the price with thousand separators', () {
      final p = GrenierProduit.fromJson({
        'id': 3,
        'name': 'Riz',
        'unit': 'kg',
        'price': 1250000,
        'currency': 'FCFA',
        'updatedAt': '2026-01-02T10:00:00Z',
      });
      expect(p.id, 3);
      expect(p.updatedAt, DateTime.utc(2026, 1, 2, 10));
      expect(p.priceLabel, '1 250 000 FCFA');
    });

    test('defaults currency to XOF', () {
      final p = GrenierProduit.fromJson({'id': 1, 'price': 500});
      expect(p.currency, 'XOF');
      expect(p.priceLabel, '500 XOF');
    });
  });
}
