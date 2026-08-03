import 'package:billetterie/src/features/event/models/event_ticket_layout.dart';

class TicketCategory {
  const TicketCategory({
    required this.id,
    required this.label,
    required this.price,
    this.currency = 'FCFA',
    this.remaining = 0,
  });

  final String id;
  final String label;
  final int price;
  final String currency;
  final int remaining;

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      id: json['id'] as String,
      label: json['label'] as String,
      price: (json['price'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'FCFA',
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

class BilletterieEvent {
  const BilletterieEvent({
    required this.id,
    required this.name,
    required this.eventType,
    required this.city,
    required this.venue,
    required this.date,
    required this.time,
    required this.description,
    required this.tags,
    required this.ticketCategories,
    this.flyerImage,
    this.rating,
    this.interestedCount,
    this.ticketsSold,
    this.expectedAttendees,
    this.conversionRate,
    this.status,
    this.startAtIso,
    this.endAtIso,
    this.latitude,
    this.longitude,
    this.tip,
    this.galleryImageUrls,
    this.ticketLayout = EventTicketLayout.horizontal,
  });

  /// Public event code from ticketing API (`eventCode`).
  final String id;
  final String name;
  final String eventType;
  final String city;
  final String venue;
  final String date;
  final String time;
  final String description;
  final List<String> tags;
  final List<TicketCategory> ticketCategories;
  final String? flyerImage;
  final double? rating;
  final int? interestedCount;
  final int? ticketsSold;
  final int? expectedAttendees;
  final int? conversionRate;
  final String? status;
  final String? startAtIso;
  final String? endAtIso;
  final double? latitude;
  final double? longitude;
  final String? tip;
  final List<String>? galleryImageUrls;
  final EventTicketLayout ticketLayout;

  /// Unit ticket price in FCFA (from API `ticketPrice` / first category).
  int get ticketPrice {
    if (ticketCategories.isEmpty) return 0;
    return ticketCategories.first.price;
  }

  /// Estimated revenue from sold tickets for this event.
  int get revenueEarned => (ticketsSold ?? 0) * ticketPrice;

  /// True when the event is not yet sold publicly.
  bool get isDraft {
    final s = (status ?? '').trim().toUpperCase();
    return s.isEmpty ||
        s == 'DRAFT' ||
        s == 'BROUILLON' ||
        s == 'CREATED' ||
        s == 'PENDING';
  }

  String get statusLabelFr {
    final s = (status ?? '').trim().toUpperCase();
    if (isDraft) return 'Brouillon';
    return switch (s) {
      'PUBLISHED' || 'PUBLIE' || 'PUBLIÉ' || 'OPEN' || 'OUVERT' => 'Publié',
      'CLOSED' || 'FERME' || 'FERMÉ' => 'Fermé',
      'CANCELLED' || 'CANCELED' || 'ANNULE' || 'ANNULÉ' => 'Annulé',
      _ => status?.trim().isNotEmpty == true ? status!.trim() : 'Brouillon',
    };
  }

  factory BilletterieEvent.fromTicketingJson(Map<String, dynamic> json) {
    final eventCode = json['eventCode']?.toString() ?? '';
    final maxTickets = _asInt(json['maxTickets']);
    final sold = _asInt(json['ticketsSold']);
    final price = (json['ticketPrice'] as num?)?.toInt() ?? 0;
    final startAt = json['startAt']?.toString();
    final endAt = json['endAt']?.toString();
    final category = json['category']?.toString() ?? 'Événement';
    final venueName = json['venueName']?.toString() ?? '';
    final address = json['address']?.toString() ?? '';
    final city = json['city']?.toString() ?? '';
    final remaining = (maxTickets - sold).clamp(0, maxTickets);
    final apiDescription = json['description']?.toString();
    final coverImage = json['coverImageUrl']?.toString();
    final gallery = json['galleryImageUrls'];
    final lat = _asDouble(json['latitude']);
    final lng = _asDouble(json['longitude']);

    return BilletterieEvent(
      id: eventCode,
      name: json['name']?.toString() ?? eventCode,
      eventType: category,
      city: city,
      venue: venueName.isNotEmpty ? venueName : address,
      date: _formatEventDate(startAt),
      time: _formatEventTime(startAt, endAt),
      description: (apiDescription != null && apiDescription.isNotEmpty)
          ? apiDescription
          : _buildDescription(
              category: category,
              venueName: venueName,
              address: address,
              city: city,
              creatorName: json['creatorName']?.toString(),
            ),
      tags: [category],
      ticketCategories: price > 0
          ? [
              TicketCategory(
                id: 'standard',
                label: 'Standard',
                price: price,
                remaining: _asInt(json['ticketsRemaining']) > 0
                    ? _asInt(json['ticketsRemaining'])
                    : remaining,
              ),
            ]
          : const [],
      flyerImage: coverImage,
      ticketsSold: sold,
      expectedAttendees: maxTickets > 0 ? maxTickets : null,
      conversionRate: maxTickets > 0 ? ((sold * 100) / maxTickets).round() : null,
      status: json['status']?.toString(),
      startAtIso: startAt,
      endAtIso: endAt,
      latitude: lat,
      longitude: lng,
      tip: json['tip']?.toString(),
      galleryImageUrls: gallery is List
          ? gallery.map((e) => e.toString()).toList(growable: false)
          : null,
      ticketLayout: EventTicketLayout.fromApi(
        json['ticketLayout']?.toString() ?? json['ticketFormat']?.toString(),
      ),
    );
  }

  static String _buildDescription({
    required String category,
    required String venueName,
    required String address,
    required String city,
    String? creatorName,
  }) {
    final parts = <String>[category];
    if (venueName.isNotEmpty) parts.add(venueName);
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (creatorName != null && creatorName.isNotEmpty) {
      parts.add('Organisé par $creatorName');
    }
    return parts.join(' • ');
  }

  static String _formatEventDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${weekdays[parsed.weekday - 1]} ${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  static String _formatEventTime(String? startIso, String? endIso) {
    final start = DateTime.tryParse(startIso ?? '');
    if (start == null) return '';
    final startLabel = '${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')}';
    final end = DateTime.tryParse(endIso ?? '');
    if (end == null) return startLabel;
    final endLabel = '${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}';
    return '$startLabel – $endLabel';
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse('$value');
}

String formatBilletterieCurrency(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf FCFA';
}
