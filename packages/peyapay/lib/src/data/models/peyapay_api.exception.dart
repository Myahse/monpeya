class PeyapayApiException implements Exception {
  PeyapayApiException({
    required this.message,
    this.statusCode,
    this.apiCode,
  });

  final String message;
  final int? statusCode;
  final String? apiCode;

  @override
  String toString() => 'PeyapayApiException($statusCode, $apiCode): $message';

  factory PeyapayApiException.fromResponse(int statusCode, dynamic body) {
    if (body is Map) {
      final status = body['status'];
      final apiMessage = status is Map ? status['message']?.toString() : null;
      final apiCode = status is Map ? status['code']?.toString() : null;
      return PeyapayApiException(
        message: apiMessage ?? 'Erreur API PeyaPay ($statusCode)',
        statusCode: statusCode,
        apiCode: apiCode,
      );
    }
    return PeyapayApiException(
      message: 'Erreur API PeyaPay ($statusCode)',
      statusCode: statusCode,
    );
  }
}
