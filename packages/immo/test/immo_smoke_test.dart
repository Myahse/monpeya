import 'package:flutter_test/flutter_test.dart';

import 'package:immo/immo.dart';

void main() {
  group('Immo barrel exports', () {
    test('ImmoHostBridge is accessible', () {
      expect(ImmoHostBridge.onExitModule, isNull);
    });

    test('ImmoBrand constants', () {
      expect(ImmoBrand.rentalPrimary.toARGB32(), 0xFF063E1C);
      expect(ImmoBrand.constructionPrimary.toARGB32(), 0xFFFF9401);
      expect(ImmoBrand.collectionPrimary.toARGB32(), 0xFF035F7B);
    });

    test('ImmoModuleKeys', () {
      expect(ImmoModuleKeys.rental, 'real-estate');
      expect(ImmoModuleKeys.construction, 'construction');
      expect(ImmoModuleKeys.collection, 'collection');
      expect(ImmoModuleKeys.all, hasLength(3));
      expect(ImmoModuleKeys.isImmoKey('real-estate'), true);
      expect(ImmoModuleKeys.isImmoKey('unknown'), false);
    });
  });

  group('ImmoEnvRegistry', () {
    test('default baseUrl is null', () {
      expect(ImmoEnvRegistry.baseUrl, isNull);
      expect(ImmoEnvRegistry.wsUrl, isNull);
      expect(ImmoEnvRegistry.mapboxAccessToken, isNull);
    });

    test('apply and reset round-trip', () {
      ImmoEnvRegistry.apply(
        baseUrl: 'http://test:8081',
        wsUrl: 'ws://test:8081/ws/realtime',
        mapboxAccessToken: 'pk.test',
      );
      expect(ImmoEnvRegistry.baseUrl, 'http://test:8081');
      expect(ImmoEnvRegistry.wsUrl, 'ws://test:8081/ws/realtime');
      expect(ImmoEnvRegistry.mapboxAccessToken, 'pk.test');
      ImmoEnvRegistry.reset();
      expect(ImmoEnvRegistry.baseUrl, isNull);
      expect(ImmoEnvRegistry.wsUrl, isNull);
      expect(ImmoEnvRegistry.mapboxAccessToken, isNull);
    });
  });

  group('ImmoApiConfig', () {
    test('baseUrl has a default', () {
      expect(ImmoApiConfig.baseUrl, isNotEmpty);
    });

    test('wsUrl is derived from baseUrl by default', () {
      expect(ImmoApiConfig.wsUrl, contains('/ws/realtime'));
    });

    test('timeoutMs is defined', () {
      expect(ImmoApiConfig.timeoutMs, 15000);
    });
  });
}
