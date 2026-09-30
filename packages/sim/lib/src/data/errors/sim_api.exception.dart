class SimApiException implements Exception {
  const SimApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  String get displayMessage => message;

  factory SimApiException.fromEnvelope(int statusCode, dynamic body) {
    if (body is Map && body['error'] is Map) {
      final error = body['error'] as Map;
      final code = error['code']?.toString();
      final msg = error['message']?.toString() ?? 'Erreur SIM Assurances';
      return SimApiException(message: msg, statusCode: statusCode, code: code);
    }
    return SimApiException(
      message: 'Erreur API SIM Assurances ($statusCode)',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'SimApiException($code, $message)';
}
