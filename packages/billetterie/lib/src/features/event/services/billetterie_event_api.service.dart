import 'package:http/http.dart' as http;

import 'package:billetterie/src/features/event/models/billetterie.event.dart';
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
  });

  final List<BilletterieEvent> events;
  final int totalTicketsGenerated;
  final int totalTicketsSold;
  final int totalTicketsConsumed;

  factory CreatorDashboardSummary.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'];
    return CreatorDashboardSummary(
      events: eventsRaw is List
          ? eventsRaw
              .whereType<Map>()
              .map(
                (e) => BilletterieEvent.fromTicketingJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      totalTicketsGenerated: _asInt(json['totalTicketsGenerated']),
      totalTicketsSold: _asInt(json['totalTicketsSold']),
      totalTicketsConsumed: _asInt(json['totalTicketsConsumed']),
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

  Future<List<BilletterieEvent>> getPublicEvents() async {
    final envelope = await _http.postItems(
      '/v1/events/public',
      data: const {},
      parser: BilletterieEvent.fromTicketingJson,
      errorMessage: 'Impossible de charger les événements',
    );
    return envelope.items ?? const [];
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
}

/// Backward-compatible alias — prefer [BilletterieEventApiService] explicitly.
typedef BilletterieApiService = BilletterieEventApiService;

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}
