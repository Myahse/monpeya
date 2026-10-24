class SimApiException implements Exception {
  const SimApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  String get displayMessage {
    if (statusCode != null && message.isNotEmpty) {
      return message;
    }
    return message;
  }

  factory SimApiException.fromEnvelope(int statusCode, dynamic body) {
    if (body is Map) {
      final nested = body['error'];
      if (nested is Map) {
        return SimApiException(
          message: _firstNonEmpty([
            nested['message']?.toString(),
            nested['detail']?.toString(),
          ]) ??
              _statusFallback(statusCode),
          statusCode: statusCode,
          code: nested['code']?.toString(),
        );
      }

      if (body['success'] == false) {
        return SimApiException(
          message: _firstNonEmpty([
                body['message']?.toString(),
                body['detail']?.toString(),
              ]) ??
              _statusFallback(statusCode),
          statusCode: statusCode,
          code: body['code']?.toString(),
        );
      }

      final listMsg = _formatErrorsList(body['errors']);
      if (listMsg != null) {
        return SimApiException(message: listMsg, statusCode: statusCode, code: body['code']?.toString());
      }

      final direct = _firstNonEmpty([
        body['message']?.toString(),
        body['detail']?.toString(),
        body['title']?.toString(),
        body['error']?.toString(),
      ]);
      if (direct != null) {
        return SimApiException(message: direct, statusCode: statusCode, code: body['code']?.toString());
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      final trimmed = body.trim();
      if (trimmed.length > 280) {
        return SimApiException(message: '${trimmed.substring(0, 277)}…', statusCode: statusCode);
      }
      return SimApiException(message: trimmed, statusCode: statusCode);
    }

    return SimApiException(message: _statusFallback(statusCode), statusCode: statusCode);
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String? _formatErrorsList(dynamic errors) {
    if (errors is! List || errors.isEmpty) return null;
    final parts = <String>[];
    for (final item in errors) {
      if (item is Map) {
        final field = item['field']?.toString() ?? item['path']?.toString();
        final msg = item['message']?.toString() ?? item['detail']?.toString();
        if (msg != null && msg.isNotEmpty) {
          parts.add(field != null && field.isNotEmpty ? '$field : $msg' : msg);
        }
      } else if (item != null) {
        parts.add(item.toString());
      }
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String _statusFallback(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Accès refusé — vérifiez SIM_API_KEY dans config/env.json.';
      case 403:
        return 'Accès interdit par SIM Assurances.';
      case 413:
        return 'Requête trop volumineuse — réduisez la taille des fichiers.';
      case 422:
        return 'Données invalides.';
      case 429:
        return 'Trop de requêtes — réessayez dans un instant.';
      case 502:
      case 503:
      case 504:
        return 'Serveur SIM Assurances indisponible — réessayez plus tard.';
      default:
        return 'Erreur API SIM Assurances ($statusCode).';
    }
  }

  @override
  String toString() => 'SimApiException($code, $message)';
}
