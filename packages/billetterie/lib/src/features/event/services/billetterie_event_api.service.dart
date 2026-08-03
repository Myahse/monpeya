import 'package:http/http.dart' as http;

import 'package:billetterie/src/features/event/models/billetterie.event.dart';
import 'package:billetterie/src/features/event/models/event_ticket_layout.dart';
import 'package:billetterie/src/shared/models/billetterie.ticket.dart';
import 'package:billetterie/src/shared/models/ticketing_api.exception.dart';
import 'package:billetterie/src/shared/config/billetterie_api.config.dart';
import 'package:billetterie/src/shared/services/ticketing_http.client.dart';

/// Creator dashboard totals for event ticketing.
class CreatorDashboardSummary {
  const CreatorDashboardSummary({
    required this.events,
    required this.totalTicketsGenerated,
    required this.totalTicketsSold,
    required this.totalTicketsConsumed,
    required this.totalRevenue,
    this.currency = 'FCFA',
  });

  final List<BilletterieEvent> events;
  final int totalTicketsGenerated;
  final int totalTicketsSold;
  final int totalTicketsConsumed;
  final int totalRevenue;
  final String currency;

  factory CreatorDashboardSummary.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'];
    final events = eventsRaw is List
        ? eventsRaw
            .whereType<Map>()
            .map(
              (e) => BilletterieEvent.fromTicketingJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : const <BilletterieEvent>[];

    final fromApi = _asInt(
      json['totalRevenue'] ??
          json['totalEarned'] ??
          json['revenue'] ??
          json['totalAmount'],
    );
    final computed = events.fold<int>(0, (sum, e) => sum + e.revenueEarned);
    final currency = json['currency']?.toString().trim();

    return CreatorDashboardSummary(
      events: events,
      totalTicketsGenerated: _asInt(json['totalTicketsGenerated']),
      totalTicketsSold: _asInt(json['totalTicketsSold']),
      totalTicketsConsumed: _asInt(json['totalTicketsConsumed']),
      totalRevenue: fromApi > 0 ? fromApi : computed,
      currency: (currency != null && currency.isNotEmpty) ? currency : 'FCFA',
    );
  }
}

/// HTTP client for **event** ticketing (`purpose = EVENT`).
///
/// Uses [BilletterieApiConfig.eventBaseUrl].
class BilletterieEventApiService {
  BilletterieEventApiService({http.Client? client, String? baseUrl})
      : _http = TicketingHttpClient(
          baseUrl: baseUrl ?? BilletterieApiConfig.eventBaseUrl,
          client: client,
        );

  final TicketingHttpClient _http;

  Future<void> ping() async {
    await _http.postSuccess(
      '/v1/ping',
      data: const {},
      errorMessage: 'Service billetterie événements indisponible',
    );
  }

  Future<List<BilletterieEvent>> getPublicEvents({
    String? category,
    bool mapOnly = false,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final data = <String, dynamic>{};
    if (category != null && category.trim().isNotEmpty) {
      data['category'] = category.trim();
    }
    if (mapOnly) data['mapOnly'] = true;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (radiusKm != null) data['radiusKm'] = radiusKm;

    final envelope = await _http.postItems(
      '/v1/events/public',
      data: data,
      parser: BilletterieEvent.fromTicketingJson,
      errorMessage: 'Impossible de charger les événements',
    );
    return envelope.items ?? const [];
  }

  Future<BilletterieEvent> createEvent({
    required String codeClient,
    required String name,
    required String category,
    required DateTime startAt,
    required DateTime endAt,
    required int ticketPrice,
    required int maxTickets,
    String? venueName,
    String? address,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    String? description,
    String? tip,
    String? coverImageUrl,
    List<String>? galleryImageUrls,
    bool preOrderEnabled = false,
    EventTicketLayout ticketLayout = EventTicketLayout.horizontal,
  }) async {
    return _http.postForItem(
      '/v1/events/create',
      data: {
        'codeClient': codeClient,
        'name': name,
        'category': category,
        'startAt': _apiDateTime(startAt),
        'endAt': _apiDateTime(endAt),
        'ticketPrice': ticketPrice,
        'maxTickets': maxTickets < 1 ? 1 : maxTickets,
        if (venueName != null && venueName.isNotEmpty) 'venueName': venueName,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (country != null && country.isNotEmpty) 'country': country,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (description != null && description.isNotEmpty) 'description': description,
        if (tip != null && tip.isNotEmpty) 'tip': tip,
        if (coverImageUrl != null && coverImageUrl.isNotEmpty) 'coverImageUrl': coverImageUrl,
        if (galleryImageUrls != null && galleryImageUrls.isNotEmpty)
          'galleryImageUrls': galleryImageUrls,
        'preOrderEnabled': preOrderEnabled,
        'ticketLayout': ticketLayout.apiValue,
        'purpose': 'EVENT',
      },
      parser: BilletterieEvent.fromTicketingJson,
      errorMessage: 'Création de l’événement impossible',
    );
  }

  Future<BilletterieEvent> publishEvent({
    required String eventCode,
    required String codeClient,
  }) async {
    return _http.postForItem(
      '/v1/events/publish',
      data: {
        'eventCode': eventCode,
        'codeClient': codeClient,
      },
      parser: BilletterieEvent.fromTicketingJson,
      errorMessage: 'Publication de l’événement impossible',
    );
  }

  Future<BilletterieEvent?> getEvent(String eventCode) async {
    try {
      return await _http.postForItem(
        '/v1/events/get',
        data: {'eventCode': eventCode},
        parser: BilletterieEvent.fromTicketingJson,
        errorMessage: 'Événement introuvable',
      );
    } on TicketingApiException catch (e) {
      if (e.apiCode == '925') return null;
      rethrow;
    }
  }

  Future<BilletterieTicket> buyTicket({
    required String ticketCode,
    required String codeClient,
    String paymentMethod = 'PEYA_WALLET',
  }) async {
    return _http.postForItem(
      '/v1/tickets/buy',
      data: {
        'ticketCode': ticketCode,
        'codeClient': codeClient,
        'paymentMethod': paymentMethod,
      },
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'Achat du billet impossible',
    );
  }

  /// Purchases the next available **FOR_SALE** ticket for a published event.
  Future<BilletterieTicket> buyTicketForEvent({
    required String eventCode,
    required String codeClient,
    String paymentMethod = 'PEYA_WALLET',
  }) async {
    return _http.postForItem(
      '/v1/tickets/buy-for-event',
      data: {
        'eventCode': eventCode,
        'codeClient': codeClient,
        'paymentMethod': paymentMethod,
      },
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'Achat du billet impossible',
    );
  }

  /// Purchased tickets for [codeClient], event only.
  Future<List<BilletterieTicket>> getMyTickets(String codeClient) async {
    final envelope = await _http.postItems(
      '/v1/tickets/my',
      data: {'codeClient': codeClient},
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'Impossible de charger vos billets',
    );
    return (envelope.items ?? const [])
        .where(_isEvent)
        .toList(growable: false);
  }

  Future<BilletterieTicket> verifyQr(String qrPayload) async {
    return _http.postForItem(
      '/v1/tickets/verify',
      data: {'qrPayload': qrPayload},
      parser: BilletterieTicket.fromTicketingJson,
      errorMessage: 'QR invalide',
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
      errorMessage: 'Validation du billet impossible',
    );
  }

  Future<CreatorDashboardSummary> getCreatorSummary(String codeClient) async {
    return _http.postForItem(
      '/v1/dashboard/creator/summary',
      data: {'codeClient': codeClient},
      parser: CreatorDashboardSummary.fromJson,
      errorMessage: 'Tableau de bord indisponible',
    );
  }

  Future<List<BilletterieEvent>> getEvents() => getPublicEvents();

  Future<BilletterieEvent?> getEventById(String id) => getEvent(id);

  static bool _isEvent(BilletterieTicket ticket) {
    final purpose = ticket.purpose?.trim().toUpperCase();
    if (purpose == 'TRANSPORT') return false;
    if (purpose == 'EVENT' || purpose == 'PASS' || purpose == 'GENERIC') {
      return true;
    }
    return ticket.eventCode != null && ticket.eventCode!.trim().isNotEmpty;
  }

  static String _apiDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = dt.toLocal();
    return '${local.year}-${two(local.month)}-${two(local.day)}'
        'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}

/// Backward-compatible alias — prefer [BilletterieEventApiService] explicitly.
typedef BilletterieApiService = BilletterieEventApiService;

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}
