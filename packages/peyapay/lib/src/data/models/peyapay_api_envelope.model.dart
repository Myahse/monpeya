class PeyapayApiEnvelope<T> {
  const PeyapayApiEnvelope({
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

  factory PeyapayApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T? Function(Map<String, dynamic> map)? itemParser,
  ) {
    final status = json['status'];
    final itemMap = _extractItemMap(json);
    return PeyapayApiEnvelope(
      hasError: json['hasError'] == true,
      message: status is Map ? status['message']?.toString() : null,
      code: status is Map ? status['code']?.toString() : null,
      item: itemMap != null && itemParser != null ? itemParser(itemMap) : null,
      items: itemParser != null && json['items'] is List
          ? (json['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(itemParser)
              .whereType<T>()
              .toList(growable: false)
          : null,
      count: json['count'] is int ? json['count'] as int : int.tryParse('${json['count']}'),
    );
  }

  static Map<String, dynamic>? _extractItemMap(Map<String, dynamic> json) {
    final item = json['item'];
    if (item is Map<String, dynamic>) return item;
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }
}
