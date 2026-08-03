import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:billetterie/src/core/constants/billetterie.prefs.dart';
import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/features/transport/services/billetterie_transport_api.service.dart';

/// Earnings snapshot for business / conductor mode.
class ConductorEarningsSummary {
  const ConductorEarningsSummary({
    required this.generatedCount,
    required this.forSaleCount,
    required this.soldCount,
    required this.consumedCount,
    required this.totalEarned,
    required this.currency,
  });

  final int generatedCount;
  final int forSaleCount;
  final int soldCount;
  final int consumedCount;
  final int totalEarned;
  final String currency;
}

class ConductorTicketStore {
  ConductorTicketStore();

  Future<List<BilletterieTransportTicket>> listAll(String issuerCodeClient) async {
    final all = await _loadRaw();
    return all
        .where((e) => e['issuerCodeClient']?.toString() == issuerCodeClient)
        .map((e) => transportTicketFromApiJson(Map<String, dynamic>.from(e)))
        .whereType<BilletterieTransportTicket>()
        .toList(growable: false);
  }

  Future<List<BilletterieTransportTicket>> listGenerated(
    String issuerCodeClient,
  ) =>
      listAll(issuerCodeClient);

  Future<List<BilletterieTransportTicket>> listSales(String issuerCodeClient) async {
    final all = await listAll(issuerCodeClient);
    return all
        .where((t) {
          final s = t.status?.toUpperCase() ?? '';
          return s == 'SOLD' ||
              s == 'CONSUMED' ||
              (t.buyerName != null && t.buyerName!.trim().isNotEmpty) ||
              t.purchasedAt != null;
        })
        .toList(growable: false);
  }

  /// Public catalog entries from local generates (`FOR_SALE` only).
  Future<List<BilletterieTransportTicket>> listForSalePublic() async {
    final all = await _loadRaw();
    return all
        .where((e) {
          final status = e['status']?.toString().toUpperCase() ?? 'FOR_SALE';
          return status == 'FOR_SALE' || status == 'GENERATED';
        })
        .map((e) => transportTicketFromApiJson(Map<String, dynamic>.from(e)))
        .whereType<BilletterieTransportTicket>()
        .toList(growable: false);
  }

  /// Tickets purchased by this client (local offline sales).
  Future<List<BilletterieTransportTicket>> listPurchasedBy(
    String buyerCodeClient,
  ) async {
    final all = await _loadRaw();
    return all
        .where((e) => e['buyerCodeClient']?.toString() == buyerCodeClient)
        .map((e) => transportTicketFromApiJson(Map<String, dynamic>.from(e)))
        .whereType<BilletterieTransportTicket>()
        .toList(growable: false);
  }

  Future<BilletterieTransportTicket?> findByCode(String ticketCode) async {
    final all = await _loadRaw();
    for (final e in all) {
      if (e['ticketCode']?.toString() == ticketCode) {
        return transportTicketFromApiJson(Map<String, dynamic>.from(e));
      }
    }
    return null;
  }

  Future<ConductorEarningsSummary> summary(String issuerCodeClient) async {
    final all = await listAll(issuerCodeClient);
    var forSale = 0;
    var sold = 0;
    var consumed = 0;
    var earned = 0;
    var currency = 'Fcfa';
    for (final t in all) {
      currency = t.currency;
      final s = (t.status ?? '').toUpperCase();
      if (s == 'CONSUMED') {
        consumed++;
        earned += t.amountPaid ?? t.price;
      } else if (s == 'SOLD' || t.purchasedAt != null) {
        sold++;
        earned += t.amountPaid ?? t.price;
      } else {
        forSale++;
      }
    }
    return ConductorEarningsSummary(
      generatedCount: all.length,
      forSaleCount: forSale,
      soldCount: sold,
      consumedCount: consumed,
      totalEarned: earned,
      currency: currency,
    );
  }

  Future<BilletterieTransportTicket> saveGenerated({
    required String issuerCodeClient,
    required BilletterieTransportTicket ticket,
  }) async {
    final all = await _loadRaw();
    final json = _toJson(ticket, issuerCodeClient);
    final code = ticket.ticketCode;
    final idx = code == null
        ? -1
        : all.indexWhere((e) => e['ticketCode']?.toString() == code);
    if (idx >= 0) {
      all[idx] = json;
    } else {
      all.insert(0, json);
    }
    await _persist(all);
    return ticket;
  }

  Future<BilletterieTransportTicket?> markSold({
    required String ticketCode,
    required String buyerCodeClient,
    String? buyerName,
    String? buyerPhone,
    int? amountPaid,
  }) async {
    final all = await _loadRaw();
    final idx = all.indexWhere((e) => e['ticketCode']?.toString() == ticketCode);
    if (idx < 0) return null;
    final row = Map<String, dynamic>.from(all[idx]);
    row['status'] = 'SOLD';
    row['buyerCodeClient'] = buyerCodeClient;
    row['buyerName'] = buyerName ?? row['buyerName'];
    row['buyerPhone'] = buyerPhone ?? row['buyerPhone'];
    row['purchasedAt'] = DateTime.now().toIso8601String();
    row['amountPaid'] = amountPaid ?? row['price'] ?? row['amountPaid'];
    row['orderRef'] ??= 'LOC-${ticketCode.replaceAll('TKT-', '')}';
    all[idx] = row;
    await _persist(all);
    return transportTicketFromApiJson(row);
  }

  Future<BilletterieTransportTicket?> markConsumed({
    required String issuerCodeClient,
    required String ticketCode,
    String? buyerName,
  }) async {
    final all = await _loadRaw();
    final idx = all.indexWhere(
      (e) => e['ticketCode']?.toString() == ticketCode,
    );
    if (idx < 0) return null;
    final row = Map<String, dynamic>.from(all[idx]);
    // Allow consume by issuer OR any scanner when ticket is local.
    if (issuerCodeClient.isNotEmpty &&
        row['issuerCodeClient']?.toString() != issuerCodeClient) {
      // Still allow if ticket exists locally (same device demo).
    }
    row['status'] = 'CONSUMED';
    if (buyerName != null && buyerName.trim().isNotEmpty) {
      row['buyerName'] = buyerName.trim();
    }
    all[idx] = row;
    await _persist(all);
    return transportTicketFromApiJson(row);
  }

  Future<List<Map<String, dynamic>>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(BilletteriePrefs.conductorTickets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BilletteriePrefs.conductorTickets, jsonEncode(rows));
  }

  Map<String, dynamic> _toJson(
    BilletterieTransportTicket ticket,
    String issuerCodeClient,
  ) {
    return {
      'purpose': 'TRANSPORT',
      'issuerCodeClient': issuerCodeClient,
      'ticketCode': ticket.ticketCode,
      'title': ticket.title ?? '${ticket.fromCity} - ${ticket.toCity}',
      'status': ticket.status ?? 'FOR_SALE',
      'ticketType': ticket.ticketType,
      'place': ticket.place,
      'validFrom': ticket.validFrom?.toIso8601String(),
      'validUntil': ticket.validUntil?.toIso8601String(),
      'durationMinutes': ticket.durationMinutes,
      'vehicleType': ticket.vehicleType,
      'vehicleNumber': ticket.vehicleNumber,
      'driverName': ticket.driverName,
      'driverPhone': ticket.driverPhone,
      'builtByName': ticket.builtByName,
      'generatedAt':
          (ticket.generatedAt ?? DateTime.now()).toIso8601String(),
      'price': ticket.price,
      'currency': ticket.currency,
      'qrPayload': ticket.qrPayload ?? ticket.resolvedQrPayload,
      'buyerName': ticket.buyerName,
      'purchasedAt': ticket.purchasedAt?.toIso8601String(),
      'amountPaid': ticket.amountPaid,
      'orderRef': ticket.orderRef,
      'paymentReference': ticket.paymentReference,
      'fromCity': ticket.fromCity,
      'toCity': ticket.toCity,
    };
  }

  static String newTicketCode() {
    final r = Random.secure();
    final hex = List.generate(4, (_) => r.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return 'TKT-$hex';
  }

  static String cityCode(String city) {
    final compact = city.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    if (compact.length >= 3) return compact.substring(0, 3).toUpperCase();
    if (compact.isEmpty) return 'XXX';
    return city.toUpperCase().padRight(3, 'X').substring(0, 3);
  }

  static String durationLabel(DateTime? from, DateTime? until) {
    if (from == null || until == null) return '';
    final mins = until.difference(from).inMinutes;
    if (mins <= 0) return '';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  static String hhmm(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
