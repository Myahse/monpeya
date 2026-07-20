class TicketingApiException implements Exception {
  TicketingApiException({
    required this.message,
    this.statusCode,
    this.apiCode,
  });

  final String message;
  final int? statusCode;
  final String? apiCode;

  @override
  String toString() => message;
}
