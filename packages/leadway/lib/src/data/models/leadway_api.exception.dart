class LeadwayApiException implements Exception {
  const LeadwayApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  factory LeadwayApiException.fromResponse(int statusCode, dynamic body) {
    if (body is Map) {
      final message = body['message']?.toString() ??
          body['error']?.toString() ??
          'Erreur API Leadway ($statusCode)';
      return LeadwayApiException(
        message: message,
        statusCode: statusCode,
        code: body['code']?.toString(),
      );
    }
    return LeadwayApiException(
      message: 'Erreur API Leadway ($statusCode)',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}
