class ImmoApiResponse<T> {
  const ImmoApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  final bool success;
  final T? data;
  final String? error;
}

class ImmoBackendEnvelope {
  const ImmoBackendEnvelope({
    this.hasError = false,
    this.items = const [],
    this.item,
    this.message,
  });

  final bool hasError;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? item;
  final String? message;

  factory ImmoBackendEnvelope.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<Map<String, dynamic>> items = const [];
    if (rawItems is List) {
      items = rawItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    Map<String, dynamic>? item;
    final rawItem = json['item'];
    if (rawItem is Map) {
      item = Map<String, dynamic>.from(rawItem);
    }

    final status = json['status'];
    String? message;
    if (status is Map) {
      message = status['message'] as String?;
    }

    return ImmoBackendEnvelope(
      hasError: json['hasError'] as bool? ?? false,
      items: items,
      item: item,
      message: message,
    );
  }
}
