import 'package:flutter_test/flutter_test.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/core/constants/immo_module.keys.dart';

void main() {
  group('Immo barrel exports', () {
    test('ImmoHostBridge is accessible', () {
      expect(ImmoHostBridge.onExitModule, isNull);
    });

    test('ImmoBrand constants', () {
      expect(ImmoBrand.rentalPrimary.value, 0xFF136734);
      expect(ImmoBrand.constructionPrimary.value, 0xFFFF9401);
      expect(ImmoBrand.collectionPrimary.value, 0xFF006D56);
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
    });

    test('apply and reset round-trip', () {
      ImmoEnvRegistry.apply(baseUrl: 'http://test:8081');
      expect(ImmoEnvRegistry.baseUrl, 'http://test:8081');
      ImmoEnvRegistry.reset();
      expect(ImmoEnvRegistry.baseUrl, isNull);
    });
  });

  group('ImmoApiConfig', () {
    test('baseUrl has a default', () {
      expect(ImmoApiConfig.baseUrl, isNotEmpty);
    });

    test('timeoutMs is defined', () {
      expect(ImmoApiConfig.timeoutMs, 15000);
    });
  });
}
