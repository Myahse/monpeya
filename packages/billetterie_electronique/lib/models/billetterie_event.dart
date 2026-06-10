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
  });

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

  factory BilletterieEvent.fromJson(Map<String, dynamic> json) {
    final cats = json['ticketCategories'];
    return BilletterieEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      eventType: json['eventType'] as String? ?? 'Événement',
      city: json['city'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      ticketCategories: cats is List
          ? cats
              .whereType<Map>()
              .map((e) => TicketCategory.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      flyerImage: json['flyerImage'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      interestedCount: (json['interestedCount'] as num?)?.toInt(),
      ticketsSold: (json['ticketsSold'] as num?)?.toInt(),
      expectedAttendees: (json['expectedAttendees'] as num?)?.toInt(),
      conversionRate: (json['conversionRate'] as num?)?.toInt(),
    );
  }
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
