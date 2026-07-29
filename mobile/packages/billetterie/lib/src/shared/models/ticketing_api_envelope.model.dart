class TicketingApiEnvelope<T> {
  const TicketingApiEnvelope({
    required this.hasError,
    this.message,
    this.code,
    this.item,
    this.items,
    this.count,
  });

  final bool hasError;
  final String? message;
  final String? code;
  final T? item;
  final List<T>? items;
  final int? count;

  factory TicketingApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T? Function(Map<String, dynamic> map)? itemParser,
  ) {
    final status = json['status'];
    return TicketingApiEnvelope(
      hasError: json['hasError'] == true,
      message: status is Map ? status['message']?.toString() : null,
      code: status is Map ? status['code']?.toString() : null,
      item: itemParser != null && json['item'] is Map<String, dynamic>
          ? itemParser(json['item'] as Map<String, dynamic>)
          : null,
      items: itemParser != null && json['items'] is List
          ? (json['items'] as List)
              .whereType<Map>()
              .map((e) => itemParser(Map<String, dynamic>.from(e)))
              .whereType<T>()
              .toList(growable: false)
          : null,
      count: json['count'] is int ? json['count'] as int : int.tryParse('${json['count']}'),
    );
  }
}
