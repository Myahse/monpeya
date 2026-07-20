import 'package:http/http.dart' as http;

import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/shared/config/billetterie_api.config.dart';
import 'package:billetterie/src/shared/models/billetterie.ticket.dart';
import 'package:billetterie/src/shared/services/ticketing_http.client.dart';

/// HTTP client for **transport** ticketing (`purpose = TRANSPORT`).
///
/// Uses [BilletterieApiConfig.transportBaseUrl].
class BilletterieTransportApiService {
  BilletterieTransportApiService({http.Client? client, String? baseUrl})
      : _http = TicketingHttpClient(
          baseUrl: baseUrl ?? BilletterieApiConfig.transportBaseUrl,
          client: client,
        );

  final TicketingHttpClient _http;

  Future<void> ping() async {
    await _http.postSuccess(
      '/v1/ping',
      data: const {},
      errorMessage: 'Service billetterie transport indisponible',
    );
  }

  /// Public catalog of transport tickets for sale.
  Future<List<BilletterieTransportTicket>> listForSale() async {
    final envelope = await _http.postItems<Map<String, dynamic>>(
      '/v1/tickets/for-sale',
      data: const {'purpose': 'TRANSPORT'},
      parser: (json) => json,
      errorMessage: 'Impossible de charger les trajets',
    );
    return (envelope.items ?? const [])
        .map(transportTicketFromApiJson)
        .whereType<BilletterieTransportTicket>()
        .toList(growable: false);
  }

  Future<BilletterieTicket> buyTicket({
    required String ticketCode,
    required String codeClient,
    String paymentMethod = 'PEYA_WALLET',
    String? buyerName,
    String? buyerPhone,
  }) async {
    return _http.postForItem(
      '/v1/tickets/buy',
      data: {
        'ticketCode': ticketCode,
        'codeClient': codeClient,
        'paymentMethod': paymentMethod,
        if (buyerName != null && buyerName.trim().isNotEmpty)
          'buyerName': buyerName.trim(),
        if (buyerPhone != null && buyerPhone.trim().isNotEmpty)
          'buyerPhone': buyerPhone.trim(),
      },
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'Achat du billet transport impossible',
    );
  }

  Future<BilletterieTicket> getTicket(String ticketCode) async {
    return _http.postForItem(
      '/v1/tickets/get',
      data: {'ticketCode': ticketCode},
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'Billet transport introuvable',
    );
  }

  /// Purchased transport tickets for [codeClient].
  Future<List<BilletterieTransportTicket>> getMyTickets(String codeClient) async {
    final envelope = await _http.postItems<Map<String, dynamic>>(
      '/v1/tickets/my',
      data: {'codeClient': codeClient},
      parser: (json) => json,
      errorMessage: 'Impossible de charger vos billets transport',
    );
    return (envelope.items ?? const [])
        .map(transportTicketFromApiJson)
        .whereType<BilletterieTransportTicket>()
        .toList(growable: false);
  }

  Future<BilletterieTicket> verifyQr(String qrPayload) async {
    return _http.postForItem(
      '/v1/tickets/verify',
      data: {'qrPayload': qrPayload},
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'QR transport invalide',
    );
  }

  Future<BilletterieTicket> consumeQr({
    required String qrPayload,
    required String scannerCodeClient,
    String? consumedPlace,
    String? scannerDeviceId,
  }) async {
    return _http.postForItem(
      '/v1/tickets/consume',
      data: {
        'qrPayload': qrPayload,
        'scannerCodeClient': scannerCodeClient,
        if (consumedPlace != null) 'consumedPlace': consumedPlace,
        if (scannerDeviceId != null) 'scannerDeviceId': scannerDeviceId,
      },
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'Validation du billet transport impossible',
    );
  }

  /// Create transport ticket(s) for sale — persists in ticketing DB.
  ///
  /// API returns `{ items: [...] }` (not a single `item`).
  Future<BilletterieTransportTicket> generateTicket({
    required String codeClient,
    required String title,
    required DateTime validFrom,
    required DateTime validUntil,
    required num price,
    required String vehicleType,
    required String vehicleNumber,
    String? place,
    String? driverCodeClient,
    String? ticketType,
    int quantity = 1,
  }) async {
    final envelope = await _http.postItems<Map<String, dynamic>>(
      '/v1/tickets/generate',
      data: {
        'codeClient': codeClient,
        'quantity': quantity < 1 ? 1 : quantity,
        'purpose': 'TRANSPORT',
        'title': title,
        'validFrom': _apiDateTime(validFrom),
        'validUntil': _apiDateTime(validUntil),
        'price': price,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        if (place != null && place.trim().isNotEmpty) 'place': place.trim(),
        if (driverCodeClient != null && driverCodeClient.trim().isNotEmpty)
          'driverCodeClient': driverCodeClient.trim(),
        if (ticketType != null && ticketType.trim().isNotEmpty)
          'ticketType': ticketType.trim(),
      },
      parser: (json) => json,
      errorMessage: 'Génération du billet impossible',
    );
    final raw = envelope.items?.isNotEmpty == true
        ? envelope.items!.first
        : envelope.item;
    if (raw == null) {
      throw StateError('Réponse generate vide');
    }
    final mapped = transportTicketFromApiJson(raw);
    if (mapped == null) {
      throw StateError('Réponse generate invalide');
    }
    return mapped;
  }

  /// Tickets issued by this conductor (`codeClient` = creator).
  Future<List<BilletterieTransportTicket>> getMyGeneratedTickets(
    String codeClient,
  ) async {
    final envelope = await _http.postItems<Map<String, dynamic>>(
      '/v1/dashboard/creator/tickets',
      data: {'codeClient': codeClient},
      parser: (json) => json,
      errorMessage: 'Impossible de charger vos billets générés',
    );
    return (envelope.items ?? const [])
        .map(transportTicketFromApiJson)
        .whereType<BilletterieTransportTicket>()
        .toList(growable: false);
  }

  /// Tickets sold (bought by clients) for this conductor.
  Future<List<BilletterieTransportTicket>> getMySales(String codeClient) async {
    final all = await getMyGeneratedTickets(codeClient);
    return all
        .where((t) {
          final s = (t.status ?? '').toUpperCase();
          return s == 'SOLD' ||
              s == 'CONSUMED' ||
              t.purchasedAt != null ||
              (t.buyerName != null && t.buyerName!.trim().isNotEmpty);
        })
        .toList(growable: false);
  }

  static String _apiDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = dt.toLocal();
    return '${local.year}-${two(local.month)}-${two(local.day)}'
        'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}

/// Maps a ticketing API ticket JSON to the transport card view model when possible.
BilletterieTransportTicket? transportTicketFromApiJson(Map<String, dynamic> json) {
  final purpose = json['purpose']?.toString().trim().toUpperCase();
  if (purpose != null && purpose.isNotEmpty && purpose != 'TRANSPORT') {
    return null;
  }

  final ticketCode = json['ticketCode']?.toString();
  final title = json['title']?.toString() ?? '';
  final parts = title.split(RegExp(r'\s*[—–\-]\s*'));
  final fromCity = (json['fromCity']?.toString().trim().isNotEmpty == true)
      ? json['fromCity'].toString().trim()
      : (parts.isNotEmpty && parts.first.trim().isNotEmpty
          ? parts.first.trim()
          : 'Départ');
  final toCity = (json['toCity']?.toString().trim().isNotEmpty == true)
      ? json['toCity'].toString().trim()
      : (parts.length > 1 && parts.last.trim().isNotEmpty
          ? parts.last.trim()
          : 'Arrivée');

  DateTime? validFrom;
  DateTime? validUntil;
  final fromRaw = json['validFrom']?.toString();
  final untilRaw = json['validUntil']?.toString();
  if (fromRaw != null) validFrom = DateTime.tryParse(fromRaw);
  if (untilRaw != null) validUntil = DateTime.tryParse(untilRaw);

  String hhmm(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String durationLabel(DateTime? from, DateTime? until, Object? minutesRaw) {
    final fromApi = minutesRaw is num
        ? minutesRaw.toInt()
        : int.tryParse('$minutesRaw');
    final mins = fromApi ??
        (from != null && until != null ? until.difference(from).inMinutes : 0);
    if (mins <= 0) return '';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String cityCode(String city) {
    final compact = city.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    if (compact.length >= 3) return compact.substring(0, 3).toUpperCase();
    if (compact.isEmpty) return 'XXX';
    return city.toUpperCase().padRight(3, 'X').substring(0, 3);
  }

  final price = (json['price'] as num?)?.toInt() ??
      (json['amountPaid'] as num?)?.toInt() ??
      0;

  final vehicleType = json['vehicleType']?.toString();

  return BilletterieTransportTicket(
    fromCode: cityCode(fromCity),
    toCode: cityCode(toCity),
    durationLabel: durationLabel(validFrom, validUntil, json['durationMinutes']),
    fromCity: fromCity,
    fromTime: hhmm(validFrom),
    toCity: toCity,
    toTime: hhmm(validUntil),
    vehicleNumber: json['vehicleNumber']?.toString() ?? '—',
    price: price,
    qrPayload: json['qrPayload']?.toString(),
    ticketCode: ticketCode,
    status: json['status']?.toString(),
    ticketType: json['ticketType']?.toString(),
    title: title.isEmpty ? null : title,
    place: json['place']?.toString(),
    validFrom: validFrom,
    validUntil: validUntil,
    preOrder: json['preOrder'] == true,
    vehicleType: vehicleType,
    driverName: json['driverName']?.toString(),
    driverPhone: json['driverPhone']?.toString(),
    builtByName: json['builtByName']?.toString(),
    generatedAt: json['generatedAt'] != null
        ? DateTime.tryParse(json['generatedAt'].toString())
        : null,
    buyerName: json['buyerName']?.toString(),
    purchasedAt: json['purchasedAt'] != null
        ? DateTime.tryParse(json['purchasedAt'].toString())
        : null,
    amountPaid: (json['amountPaid'] as num?)?.toInt(),
    orderRef: json['orderRef']?.toString(),
    paymentReference: json['paymentReference']?.toString(),
  );
}
