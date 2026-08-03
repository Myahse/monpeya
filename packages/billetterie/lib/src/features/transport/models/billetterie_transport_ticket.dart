
class BilletterieTransportTicket {
  const BilletterieTransportTicket({
    required this.fromCode,
    required this.toCode,
    required this.durationLabel,
    required this.fromCity,
    required this.fromTime,
    required this.toCity,
    required this.toTime,
    required this.vehicleNumber,
    required this.price,
    this.currency = 'Fcfa',
    this.vehicleImageUrl,
    this.qrPayload,
    this.ticketCode,
    this.status,
    this.ticketType,
    this.title,
    this.place,
    this.validFrom,
    this.validUntil,
    this.preOrder = false,
    this.vehicleType,
    this.driverName,
    this.driverPhone,
    this.builtByName,
    this.generatedAt,
    this.buyerName,
    this.purchasedAt,
    this.amountPaid,
    this.orderRef,
    this.paymentReference,
    this.sellerName,
    this.receiptSubtitle,
    this.salesChannel,
  });

  final String fromCode;
  final String toCode;
  final String durationLabel;
  final String fromCity;
  final String fromTime;
  final String toCity;
  final String toTime;
  final String vehicleNumber;
  final int price;
  final String currency;
  final String? vehicleImageUrl;

  /// Payload encoded in the ticket QR (owned tickets).
  final String? qrPayload;


  /// Public identifier, e.g. `TKT-A1B2C3D4`.
  final String? ticketCode;

  /// `GENERATED` · `FOR_SALE` · `SOLD` · `CONSUMED` · `CANCELLED`.
  final String? status;

  /// Creator-defined category (STANDARD, VIP, VVIP, …).
  final String? ticketType;

  /// Display label (route name), e.g. `Cocody — Treichville`.
  final String? title;

  /// Location / boarding point, e.g. `Gare routière`.
  final String? place;

  /// Start of validity / trip.
  final DateTime? validFrom;

  /// End of validity / trip.
  final DateTime? validUntil;

  /// Whether the ticket was offered as pre-order before official sale.
  final bool preOrder;

  /// `CAR`, `BUS`, `MINIBUS`, `TAXI`, `MOTORBIKE`, `TRUCK`, `OTHER`.
  final String? vehicleType;

  /// Assigned driver (resolved from Peya).
  final String? driverName;
  final String? driverPhone;

  /// Issuer / creator display name.
  final String? builtByName;
  final DateTime? generatedAt;

  // --- Purchase info (null while the ticket is only FOR_SALE) ---
  final String? buyerName;
  final DateTime? purchasedAt;
  final int? amountPaid;
  final String? orderRef;
  final String? paymentReference;
  final String? sellerName;
  final String? receiptSubtitle;
  final String? salesChannel;

  /// Duration in minutes parsed from [durationLabel] (e.g. '20min' → 20).
  int get durationMinutes =>
      int.tryParse(durationLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String get routeKey => '$fromCode→$toCode';

  String get resolvedQrPayload =>
      qrPayload ??
      'billetterie://ticket'
          '?from=$fromCode'
          '&to=$toCode'
          '&vehicle=$vehicleNumber'
          '&price=$price';


  static final sample = BilletterieTransportTicket(
    fromCode: 'CCDY',
    toCode: 'TRCH',
    durationLabel: '20min',
    fromCity: 'Abj',
    fromTime: '9h00',
    toCity: 'Abj',
    toTime: '9h20',
    vehicleNumber: 'AA 01452',
    price: 2000,
    qrPayload: 'billetterie://ticket/CCDY-TRCH-AA01452',
    ticketCode: 'TKT-A1B2C3D4',
    status: 'FOR_SALE',
    ticketType: 'STANDARD',
    title: 'Cocody — Treichville',
    place: 'Gare de Cocody',
    validFrom: DateTime(2026, 7, 16, 9, 0),
    validUntil: DateTime(2026, 7, 16, 9, 20),
    vehicleType: 'MINIBUS',
    driverName: 'Konan Yao',
    driverPhone: '+225 07 08 12 34 56',
    builtByName: 'Transport Espoir',
    generatedAt: DateTime(2026, 7, 15, 18, 30),
  );

  static final samples = <BilletterieTransportTicket>[
    sample,
    BilletterieTransportTicket(
      fromCode: 'CCDY',
      toCode: 'TRCH',
      durationLabel: '25min',
      fromCity: 'Abj',
      fromTime: '9h30',
      toCity: 'Abj',
      toTime: '9h55',
      vehicleNumber: 'AA 01887',
      price: 2200,
      qrPayload: 'billetterie://ticket/CCDY-TRCH-AA01887',
      ticketCode: 'TKT-B2C3D4E5',
      status: 'FOR_SALE',
      ticketType: 'STANDARD',
      title: 'Cocody — Treichville',
      place: 'Gare de Cocody',
      validFrom: DateTime(2026, 7, 16, 9, 30),
      validUntil: DateTime(2026, 7, 16, 9, 55),
      vehicleType: 'BUS',
      driverName: 'Bakayoko Issa',
      driverPhone: '+225 05 44 22 18 90',
      builtByName: 'Transport Espoir',
      generatedAt: DateTime(2026, 7, 15, 18, 30),
    ),
    BilletterieTransportTicket(
      fromCode: 'PLTE',
      toCode: 'YOP',
      durationLabel: '35min',
      fromCity: 'Abj',
      fromTime: '10h00',
      toCity: 'Abj',
      toTime: '10h35',
      vehicleNumber: 'AA 02214',
      price: 1800,
      qrPayload: 'billetterie://ticket/PLTE-YOP-AA02214',
      ticketCode: 'TKT-C3D4E5F6',
      status: 'FOR_SALE',
      ticketType: 'STANDARD',
      title: 'Plateau — Yopougon',
      place: 'Gare Sud, Plateau',
      validFrom: DateTime(2026, 7, 16, 10, 0),
      validUntil: DateTime(2026, 7, 16, 10, 35),
      vehicleType: 'BUS',
      driverName: 'Ouattara Adama',
      driverPhone: '+225 01 02 55 66 77',
      builtByName: 'Sotra Express',
      generatedAt: DateTime(2026, 7, 15, 20, 10),
    ),
    BilletterieTransportTicket(
      fromCode: 'PLTE',
      toCode: 'YOP',
      durationLabel: '28min',
      fromCity: 'Abj',
      fromTime: '10h30',
      toCity: 'Abj',
      toTime: '10h58',
      vehicleNumber: 'AA 02890',
      price: 2100,
      qrPayload: 'billetterie://ticket/PLTE-YOP-AA02890',
      ticketCode: 'TKT-D4E5F6G7',
      status: 'FOR_SALE',
      ticketType: 'VIP',
      title: 'Plateau — Yopougon',
      place: 'Gare Sud, Plateau',
      validFrom: DateTime(2026, 7, 16, 10, 30),
      validUntil: DateTime(2026, 7, 16, 10, 58),
      preOrder: true,
      vehicleType: 'MINIBUS',
      driverName: 'Kouadio Franck',
      driverPhone: '+225 07 77 88 99 00',
      builtByName: 'Sotra Express',
      generatedAt: DateTime(2026, 7, 15, 20, 10),
    ),
    BilletterieTransportTicket(
      fromCode: 'MRC',
      toCode: 'CCDY',
      durationLabel: '40min',
      fromCity: 'Abj',
      fromTime: '11h15',
      toCity: 'Abj',
      toTime: '11h55',
      vehicleNumber: 'AA 03102',
      price: 2500,
      qrPayload: 'billetterie://ticket/MRC-CCDY-AA03102',
      ticketCode: 'TKT-E5F6G7H8',
      status: 'FOR_SALE',
      ticketType: 'STANDARD',
      title: 'Marcory — Cocody',
      place: 'Gare de Marcory',
      validFrom: DateTime(2026, 7, 16, 11, 15),
      validUntil: DateTime(2026, 7, 16, 11, 55),
      vehicleType: 'BUS',
      driverName: 'Diabaté Moussa',
      driverPhone: '+225 05 12 34 78 90',
      builtByName: 'Ivoire Mobilité',
      generatedAt: DateTime(2026, 7, 16, 6, 45),
    ),
    BilletterieTransportTicket(
      fromCode: 'MRC',
      toCode: 'CCDY',
      durationLabel: '35min',
      fromCity: 'Abj',
      fromTime: '11h45',
      toCity: 'Abj',
      toTime: '12h20',
      vehicleNumber: 'AA 03654',
      price: 2600,
      qrPayload: 'billetterie://ticket/MRC-CCDY-AA03654',
      ticketCode: 'TKT-F6G7H8I9',
      status: 'FOR_SALE',
      ticketType: 'VIP',
      title: 'Marcory — Cocody',
      place: 'Gare de Marcory',
      validFrom: DateTime(2026, 7, 16, 11, 45),
      validUntil: DateTime(2026, 7, 16, 12, 20),
      vehicleType: 'CAR',
      driverName: 'N’Guessan Éric',
      driverPhone: '+225 07 55 41 20 63',
      builtByName: 'Ivoire Mobilité',
      generatedAt: DateTime(2026, 7, 16, 6, 45),
    ),
    BilletterieTransportTicket(
      fromCode: 'YOP',
      toCode: 'TRCH',
      durationLabel: '30min',
      fromCity: 'Abj',
      fromTime: '12h00',
      toCity: 'Abj',
      toTime: '12h30',
      vehicleNumber: 'AA 01452',
      price: 2000,
      qrPayload: 'billetterie://ticket/YOP-TRCH-AA01452',
      ticketCode: 'TKT-G7H8I9J0',
      status: 'FOR_SALE',
      ticketType: 'STANDARD',
      title: 'Yopougon — Treichville',
      place: 'Gare de Yopougon',
      validFrom: DateTime(2026, 7, 16, 12, 0),
      validUntil: DateTime(2026, 7, 16, 12, 30),
      vehicleType: 'MINIBUS',
      driverName: 'Konan Yao',
      driverPhone: '+225 07 08 12 34 56',
      builtByName: 'Transport Espoir',
      generatedAt: DateTime(2026, 7, 16, 7, 20),
    ),
    BilletterieTransportTicket(
      fromCode: 'YOP',
      toCode: 'TRCH',
      durationLabel: '24min',
      fromCity: 'Abj',
      fromTime: '12h30',
      toCity: 'Abj',
      toTime: '12h54',
      vehicleNumber: 'AA 04120',
      price: 2400,
      qrPayload: 'billetterie://ticket/YOP-TRCH-AA04120',
      ticketCode: 'TKT-H8I9J0K1',
      status: 'FOR_SALE',
      ticketType: 'VIP',
      title: 'Yopougon — Treichville',
      place: 'Gare de Yopougon',
      validFrom: DateTime(2026, 7, 16, 12, 30),
      validUntil: DateTime(2026, 7, 16, 12, 54),
      vehicleType: 'CAR',
      driverName: 'Traoré Salif',
      driverPhone: '+225 01 45 67 89 01',
      builtByName: 'Transport Espoir',
      generatedAt: DateTime(2026, 7, 16, 7, 20),
    ),
    BilletterieTransportTicket(
      fromCode: 'CCDY',
      toCode: 'PLTE',
      durationLabel: '18min',
      fromCity: 'Abj',
      fromTime: '13h10',
      toCity: 'Abj',
      toTime: '13h28',
      vehicleNumber: 'AA 04561',
      price: 1500,
      qrPayload: 'billetterie://ticket/CCDY-PLTE-AA04561',
      ticketCode: 'TKT-I9J0K1L2',
      status: 'FOR_SALE',
      ticketType: 'STANDARD',
      title: 'Cocody — Plateau',
      place: 'Carrefour Riviera',
      validFrom: DateTime(2026, 7, 16, 13, 10),
      validUntil: DateTime(2026, 7, 16, 13, 28),
      vehicleType: 'MINIBUS',
      driverName: 'Koné Ibrahim',
      driverPhone: '+225 05 98 76 54 32',
      builtByName: 'Ivoire Mobilité',
      generatedAt: DateTime(2026, 7, 16, 8, 0),
    ),
    BilletterieTransportTicket(
      fromCode: 'CCDY',
      toCode: 'PLTE',
      durationLabel: '15min',
      fromCity: 'Abj',
      fromTime: '13h40',
      toCity: 'Abj',
      toTime: '13h55',
      vehicleNumber: 'AA 04987',
      price: 1700,
      qrPayload: 'billetterie://ticket/CCDY-PLTE-AA04987',
      ticketCode: 'TKT-J0K1L2M3',
      status: 'FOR_SALE',
      ticketType: 'VIP',
      title: 'Cocody — Plateau',
      place: 'Carrefour Riviera',
      validFrom: DateTime(2026, 7, 16, 13, 40),
      validUntil: DateTime(2026, 7, 16, 13, 55),
      preOrder: true,
      vehicleType: 'CAR',
      driverName: 'Aka Simon',
      driverPhone: '+225 07 33 21 45 67',
      builtByName: 'Ivoire Mobilité',
      generatedAt: DateTime(2026, 7, 16, 8, 0),
    ),
    BilletterieTransportTicket(
      fromCode: 'TRCH',
      toCode: 'MRC',
      durationLabel: '45min',
      fromCity: 'Abj',
      fromTime: '14h00',
      toCity: 'Abj',
      toTime: '14h45',
      vehicleNumber: 'AA 01990',
      price: 2800,
      qrPayload: 'billetterie://ticket/TRCH-MRC-AA01990',
      ticketCode: 'TKT-K1L2M3N4',
      status: 'FOR_SALE',
      ticketType: 'STANDARD',
      title: 'Treichville — Marcory',
      place: 'Gare de Treichville',
      validFrom: DateTime(2026, 7, 16, 14, 0),
      validUntil: DateTime(2026, 7, 16, 14, 45),
      vehicleType: 'BUS',
      driverName: 'Gnahoré Paul',
      driverPhone: '+225 01 23 45 67 89',
      builtByName: 'Sotra Express',
      generatedAt: DateTime(2026, 7, 16, 9, 15),
    ),
    BilletterieTransportTicket(
      fromCode: 'PLTE',
      toCode: 'CCDY',
      durationLabel: '22min',
      fromCity: 'Abj',
      fromTime: '15h20',
      toCity: 'Abj',
      toTime: '15h42',
      vehicleNumber: 'AA 02733',
      price: 1900,
      qrPayload: 'billetterie://ticket/PLTE-CCDY-AA02733',
      ticketCode: 'TKT-L2M3N4O5',
      status: 'FOR_SALE',
      ticketType: 'STANDARD',
      title: 'Plateau — Cocody',
      place: 'Gare Nord, Plateau',
      validFrom: DateTime(2026, 7, 16, 15, 20),
      validUntil: DateTime(2026, 7, 16, 15, 42),
      vehicleType: 'MINIBUS',
      driverName: 'Séka Marius',
      driverPhone: '+225 05 67 12 89 04',
      builtByName: 'Sotra Express',
      generatedAt: DateTime(2026, 7, 16, 10, 5),
    ),
  ];
}

/// Badge shown on a ticket card, computed from the displayed list.
enum BilletterieTicketBadgeKind {
  /// Cheapest offer on its route (blue).
  cheaper,

  /// Cheapest AND fastest offer on its route (red).
  cheaperFaster,
}

class BilletterieTicketBadge {
  const BilletterieTicketBadge({required this.label, required this.kind});

  final String label;
  final BilletterieTicketBadgeKind kind;

  static const cheaper = BilletterieTicketBadge(
    label: 'Moins chère',
    kind: BilletterieTicketBadgeKind.cheaper,
  );

  static const cheaperFaster = BilletterieTicketBadge(
    label: 'Moins chère & rapide',
    kind: BilletterieTicketBadgeKind.cheaperFaster,
  );
}

/// Computes badges aligned with [tickets] (same indexes).
///
/// Per route: the cheapest offer gets [BilletterieTicketBadge.cheaper]; if it
/// is also the fastest it gets [BilletterieTicketBadge.cheaperFaster] instead.
/// Routes with a single offer get no badge.
List<BilletterieTicketBadge?> computeTicketBadges(
  List<BilletterieTransportTicket> tickets,
) {
  final byRoute = <String, List<int>>{};
  for (var i = 0; i < tickets.length; i++) {
    byRoute.putIfAbsent(tickets[i].routeKey, () => []).add(i);
  }

  final badges = List<BilletterieTicketBadge?>.filled(tickets.length, null);
  for (final indexes in byRoute.values) {
    if (indexes.length < 2) continue;
    var minPrice = tickets[indexes.first].price;
    var minDuration = tickets[indexes.first].durationMinutes;
    for (final i in indexes) {
      if (tickets[i].price < minPrice) minPrice = tickets[i].price;
      if (tickets[i].durationMinutes < minDuration) {
        minDuration = tickets[i].durationMinutes;
      }
    }
    for (final i in indexes) {
      final t = tickets[i];
      if (t.price != minPrice) continue;
      badges[i] = t.durationMinutes == minDuration
          ? BilletterieTicketBadge.cheaperFaster
          : BilletterieTicketBadge.cheaper;
    }
  }
  return badges;
}
