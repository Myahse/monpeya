/// Erreur de validation / métier renvoyée par l'API Leadway.
class LeadwayApiFieldError {
  const LeadwayApiFieldError({
    required this.message,
    this.field,
  });

  final String message;
  final String? field;

  factory LeadwayApiFieldError.fromJson(Map<String, dynamic> json) {
    return LeadwayApiFieldError(
      message: json['message']?.toString() ?? '',
      field: json['field']?.toString(),
    );
  }
}

class LeadwayApiException implements Exception {
  const LeadwayApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const [],
  });

  /// Leadway gateway unreachable (network down, timeout, TLS failure).
  static const unreachable = LeadwayApiException(
    message: 'Impossible de joindre Leadway. Vérifiez votre connexion et réessayez.',
  );

  final String message;
  final int? statusCode;
  final String? code;
  final List<LeadwayApiFieldError> fieldErrors;

  /// Message prêt pour l'UI (toast / snackbar).
  String get displayMessage {
    if (fieldErrors.isNotEmpty) {
      final parts = fieldErrors
          .map((e) => e.message.trim())
          .where((m) => m.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join('\n');
    }
    return message;
  }

  factory LeadwayApiException.fromResponse(int statusCode, dynamic body) {
    if (body is! Map) {
      return LeadwayApiException(
        message: 'Erreur API Leadway ($statusCode)',
        statusCode: statusCode,
      );
    }

    final map = Map<String, dynamic>.from(body);
    final fieldErrors = _parseFieldErrors(map['errors']);

    if (fieldErrors.isNotEmpty) {
      final messages = fieldErrors
          .map((e) => e.message.trim())
          .where((m) => m.isNotEmpty)
          .toList();
      return LeadwayApiException(
        message: messages.isNotEmpty
            ? messages.join('\n')
            : 'Erreur API Leadway ($statusCode)',
        statusCode: statusCode,
        code: map['code']?.toString() ?? map['status']?.toString(),
        fieldErrors: fieldErrors,
      );
    }

    final message = map['message']?.toString() ??
        map['error']?.toString() ??
        map['detail']?.toString() ??
        'Erreur API Leadway ($statusCode)';

    return LeadwayApiException(
      message: message,
      statusCode: statusCode,
      code: map['code']?.toString(),
    );
  }

  static List<LeadwayApiFieldError> _parseFieldErrors(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => LeadwayApiFieldError.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.message.trim().isNotEmpty)
        .toList();
  }

  @override
  String toString() => displayMessage;
}
