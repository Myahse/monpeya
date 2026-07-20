import 'package:flutter_test/flutter_test.dart';

import 'package:peyapay/peyapay.dart';

void main() {
  group('Peyapay barrel exports', () {
    test('PeyapayHostBridge is accessible', () {
      expect(PeyapayHostBridge.monPeyaLogoAssetPath, isNotEmpty);
    });

    test('PeyapayHostRoutes are defined', () {
      expect(PeyapayHostRoutes.phoneInput, '/phone');
      expect(PeyapayHostRoutes.settings, '/settings');
    });

    test('PeyapayApiConfig constants are defined', () {
      expect(PeyapayApiConfig.defaultDevBaseUrl, isNotEmpty);
      expect(PeyapayApiConfig.defaultProdBaseUrl, isNotEmpty);
      expect(PeyapayApiConfig.defaultCryptoBaseUrl, isNotEmpty);
      expect(PeyapayApiConfig.defaultResidenceCountry, 'CI');
      expect(PeyapayApiConfig.defaultAgenceCode, '11111');
      expect(PeyapayApiConfig.apiTimeout, const Duration(seconds: 30));
    });

    test('PeyapayApiConstants asset helper', () {
      expect(PeyaPayAssets.brandLogo, isNotEmpty);
      expect(PeyaPayAssets.logo('test.png'), 'assets/logo/test.png');
      expect(PeyaPayAssets.bank('test.png'), 'assets/logo/banks/test.png');
      expect(PeyaPayAssets.card('test.png'), 'assets/logo/cards/test.png');
    });
  });

  group('PeyapayApiException', () {
    test('constructs with message', () {
      final e = PeyapayApiException(message: 'Test error');
      expect(e.toString(), contains('Test error'));
    });

    test('constructs with status code and api code', () {
      final e = PeyapayApiException(message: 'Not found', statusCode: 404, apiCode: '925');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('925'));
    });

    test('fromResponse parses status map', () {
      final e = PeyapayApiException.fromResponse(500, {
        'status': {'code': '919', 'message': 'Erreur serveur'},
      });
      expect(e.statusCode, 500);
      expect(e.apiCode, '919');
      expect(e.message, contains('Erreur serveur'));
    });
  });

  group('PeyapayAuthToken', () {
    test('fromJson parses token', () {
      final t = PeyapayAuthToken.fromJson({'token': 'jwt-abc', 'refreshToken': 'refresh-xyz'});
      expect(t.token, 'jwt-abc');
      expect(t.refreshToken, 'refresh-xyz');
    });

    test('fromJson handles missing fields', () {
      final t = PeyapayAuthToken.fromJson({});
      expect(t.token, '');
      expect(t.refreshToken, isNull);
      expect(t.roles, isEmpty);
    });
  });

  group('PeyapayGsmSearchResult', () {
    test('empty result', () {
      const r = PeyapayGsmSearchResult(count: 0);
      expect(r.isRecognized, false);
      expect(r.firstProfile, isNull);
    });

    test('recognized profile', () {
      final r = PeyapayGsmSearchResult(
        count: 1,
        items: [
          PeyapayGsmClientProfile(codeClient: 'C001', nomClient: 'Alice'),
        ],
      );
      expect(r.isRecognized, true);
      expect(r.firstProfile?.codeClient, 'C001');
      expect(r.firstProfile?.nomClient, 'Alice');
    });
  });

  group('PeyapayPinVerificationResult', () {
    test('fromJson', () {
      final r = PeyapayPinVerificationResult.fromJson({
        'gsmPrincipale': '0102030405',
        'codePaysResidence': 'CI',
        'solde': '50000',
      });
      expect(r.gsmPrincipale, '0102030405');
      expect(r.solde, '50000');
    });
  });

  group('PeyapayApiEnvelope', () {
    test('parses successful envelope', () {
      final e = PeyapayApiEnvelope<Map<String, dynamic>>.fromJson(
        {
          'hasError': false,
          'status': {'code': '800', 'message': 'OK'},
          'item': {'key': 'value'},
        },
        (json) => json,
      );
      expect(e.hasError, false);
      expect(e.code, '800');
      expect(e.item, isNotNull);
      expect(e.item!['key'], 'value');
    });

    test('parses envelope with error', () {
      final e = PeyapayApiEnvelope<Map<String, dynamic>>.fromJson(
        {
          'hasError': true,
          'status': {'code': '919', 'message': 'Erreur'},
        },
        null,
      );
      expect(e.hasError, true);
      expect(e.code, '919');
      expect(e.item, isNull);
    });
  });

  group('TransactionItem', () {
    test('constructs and computes fields', () {
      final t = TransactionItem(
        id: 'txn-1',
        recipient: 'Alice',
        dateIso: '2024-01-15T10:00:00',
        amount: 5000,
        type: TransactionType.transfer,
        status: TransactionStatus.completed,
      );
      expect(t.id, 'txn-1');
      expect(t.isCredit, true);
      expect(t.typeLabel, 'Transfert');
      expect(t.statusLabel, 'Complétée');
    });

    test('negative amount is debit', () {
      final t = TransactionItem(
        id: 'txn-2',
        recipient: 'Bob',
        dateIso: '2024-01-15T10:00:00',
        amount: -2000,
        type: TransactionType.payment,
        status: TransactionStatus.pending,
      );
      expect(t.isCredit, false);
      expect(t.typeLabel, 'Paiement');
      expect(t.statusLabel, 'En cours');
    });
  });

  group('PeyapayCryptoService', () {
    test('looksLikeEncrypted detects ciphers', () {
      expect(PeyapayCryptoService.looksLikeEncrypted('abc123'), false);
      expect(PeyapayCryptoService.looksLikeEncrypted('12345'), false);
      expect(PeyapayCryptoService.looksLikeEncrypted('DPAY-test'), false);
      expect(PeyapayCryptoService.looksLikeEncrypted('QUJDREVGR0hJSktMTU5QUA=='), true);
      expect(PeyapayCryptoService.looksLikeEncrypted(''), false);
    });

    test('maskCipher truncates long values', () {
      expect(PeyapayCryptoService.maskCipher(''), '(empty)');
      expect(PeyapayCryptoService.maskCipher('abc'), 'abc (3 chars)');
      expect(
        PeyapayCryptoService.maskCipher('abcdefghijklmnopq'),
        startsWith('abcdefghijkl'),
      );
    });
  });

  group('Formatters', () {
    test('formatFrMoneySigned formats positive', () {
      expect(formatFrMoneySigned(0), '0');
      expect(formatFrMoneySigned(1000), '1 000');
      expect(formatFrMoneySigned(1000000), '1 000 000');
    });

    test('formatFrMoneySigned formats negative', () {
      expect(formatFrMoneySigned(-500), '-500');
      expect(formatFrMoneySigned(-1500), '-1 500');
    });

    test('formatFrDateOnly formats ISO', () {
      final r = formatFrDateOnly('2024-03-15T10:30:00');
      expect(r, isNotEmpty);
      expect(r, contains('/'));
    });

    test('formatFrDateOnly handles empty', () {
      expect(formatFrDateOnly(''), '');
    });
  });

  group('normalizePeyapayPhone', () {
    test('strips country codes', () {
      expect(normalizePeyapayPhone('+2250102030405'), '0102030405');
      expect(normalizePeyapayPhone('002250102030405'), '0102030405');
      expect(normalizePeyapayPhone('2250102030405'), '0102030405');
    });

    test('keeps 10-digit local', () {
      expect(normalizePeyapayPhone('0102030405'), '0102030405');
      expect(normalizePeyapayPhone('01 02 03 04 05'), '0102030405');
    });
  });
}
