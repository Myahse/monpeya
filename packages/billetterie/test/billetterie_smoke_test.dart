import 'package:flutter_test/flutter_test.dart';

import 'package:billetterie/billetterie.dart';

void main() {
  group('Billetterie barrel exports', () {
    test('BilletterieHostBridge is accessible', () {
      expect(BilletterieHostBridge.onPayment, isNull);
      expect(BilletterieHostBridge.onExitModule, isNull);
    });

    test('BilletterieEnvRegistry defaults', () {
      expect(BilletterieEnvRegistry.baseUrl, isNull);
    });

    test('BilletterieModuleKeys', () {
      expect(BilletterieModuleKeys.transport, 'billetterie-transport');
      expect(BilletterieModuleKeys.event, 'billetterie-event');
      expect(BilletterieModuleKeys.isBilletterieKey('billetterie-transport'), true);
      expect(BilletterieModuleKeys.isBilletterieKey('unknown'), false);
    });

    test('BilletterieBrand is defined', () {
      expect(BilletterieBrand.light.primary.toARGB32(), 0xFF38BDF8);
      expect(BilletterieBrand.dark.text.toARGB32(), 0xFFF1F5F9);
      expect(BilletterieBrand.eventLight.primaryDark.toARGB32(), 0xFF7C3AED);
    });
  });

  group('BilletterieApiConfig (internal)', () {
    test('timeout is 20 seconds', () {
      expect(BilletterieApiConfig.apiTimeout, const Duration(seconds: 20));
    });

    test('baseUrl has a default', () {
      expect(BilletterieApiConfig.baseUrl, isNotEmpty);
    });

    test('transport and event URLs fall back to baseUrl', () {
      expect(BilletterieApiConfig.transportBaseUrl, BilletterieApiConfig.baseUrl);
      expect(BilletterieApiConfig.eventBaseUrl, BilletterieApiConfig.baseUrl);
    });
  });

  group('Ticketing API clients', () {
    test('transport and event services construct', () {
      expect(BilletterieTransportApiService.new, isNotNull);
      expect(BilletterieEventApiService.new, isNotNull);
      expect(BilletterieApiService.new, isNotNull);
    });
  });

  group('BilletterieEvent', () {
    test('fromTicketingJson parses minimal event', () {
      final e = BilletterieEvent.fromTicketingJson({
        'eventCode': 'EVT-001',
        'name': 'Concert',
      });
      expect(e.id, 'EVT-001');
      expect(e.name, 'Concert');
      expect(e.ticketCategories, isEmpty);
    });

    test('fromTicketingJson parses full event', () {
      final e = BilletterieEvent.fromTicketingJson({
        'eventCode': 'EVT-002',
        'name': 'Festival',
        'city': 'Abidjan',
        'venueName': 'Palais',
        'category': 'Concert',
        'startAt': '2026-07-01T18:00:00.000Z',
        'endAt': '2026-07-01T23:00:00.000Z',
        'status': 'PUBLISHED',
        'ticketPrice': 25000,
        'maxTickets': 100,
        'ticketsSold': 10,
      });
      expect(e.id, 'EVT-002');
      expect(e.city, 'Abidjan');
      expect(e.ticketCategories, hasLength(1));
      expect(e.ticketCategories.first.label, 'Standard');
      expect(e.ticketCategories.first.price, 25000);
    });
  });

  group('BilletterieTicket', () {
    test('fromTicketingJson parses ticket', () {
      final t = BilletterieTicket.fromTicketingJson({
        'ticketCode': 'TKT-1',
        'eventCode': 'EVT-1',
        'purpose': 'EVENT',
        'title': 'Concert',
        'buyerName': 'Ada',
        'purchasedAt': '2026-07-01T12:00:00.000Z',
        'qrPayload': 'payload',
        'amountPaid': 5000,
        'status': 'SOLD',
        'orderRef': 'ORD-1',
      });
      expect(t.id, 'TKT-1');
      expect(t.eventCode, 'EVT-1');
      expect(t.holderName, 'Ada');
      expect(t.amount, 5000);
      expect(t.status, 'SOLD');
    });

    test('copyWith replaces qrPayload', () {
      final t = BilletterieTicket.fromTicketingJson({
        'ticketCode': 'TKT-2',
        'qrPayload': 'old',
      });
      expect(t.copyWith(qrPayload: 'new').qrPayload, 'new');
    });

    test('toJson round-trips', () {
      final t = BilletterieTicket.fromTicketingJson({
        'ticketCode': 'TKT-3',
        'title': 'Pass',
        'buyerName': 'Bob',
        'qrPayload': 'qr',
        'amountPaid': 1000,
      });
      final again = BilletterieTicket.fromJson(t.toJson());
      expect(again.id, t.id);
      expect(again.qrPayload, t.qrPayload);
      expect(again.amount, t.amount);
    });
  });

  group('BilletterieTicketType', () {
    test('fromJson parses', () {
      final type = BilletterieTicketType.fromJson({
        'id': 'type-1',
        'name': 'Standard',
        'scope': 'event',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'price': 12.5,
        'currency': 'XOF',
      });
      expect(type.id, 'type-1');
      expect(type.scope, 'event');
      expect(type.price, 12.5);
    });
  });

  group('BilletterieHostPayment helpers', () {
    test('encodeQrPayload encodes JSON', () {
      final payload = encodeQrPayload({'ticketCode': 'T-1'});
      expect(payload, contains('T-1'));
    });
  });

  group('formatBilletterieCurrency', () {
    test('formats amounts', () {
      expect(formatBilletterieCurrency(0), '0 FCFA');
      expect(formatBilletterieCurrency(1000), '1 000 FCFA');
      expect(formatBilletterieCurrency(100000), '100 000 FCFA');
    });
  });
}
