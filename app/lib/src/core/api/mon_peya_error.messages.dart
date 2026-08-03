import 'package:app/src/core/api/mon_peya_api.exception.dart';

/// User-facing Mon Peya backend error copy — never expose raw server messages.
abstract final class MonPeyaErrorMessages {
  MonPeyaErrorMessages._();

  static const serverUnavailable =
      'Le serveur Mon Peya est momentanément indisponible. '
      'Vérifiez votre connexion et réessayez dans quelques instants.';

  static const serverUnreachable =
      'Impossible de joindre le serveur Mon Peya. '
      'Vérifiez que le téléphone et le PC sont sur le même réseau, '
      'puis réessayez.';

  static const genericFailure =
      'Une erreur est survenue. Veuillez réessayer.';

  static const dialogTitleUnavailable = 'Service indisponible';
  static const dialogTitleError = 'Erreur';

  static String sanitizeRaw(String? raw, {required String fallback}) {
    final msg = raw?.trim();
    if (msg == null || msg.isEmpty) return fallback;
    if (_isTechnical(msg)) return fallback;
    return msg;
  }

  static String forException(MonPeyaApiException error) {
    if (_isAlreadyFriendly(error.message)) return error.message;
    if (_isInfrastructure(error)) {
      return error.statusCode != null && error.statusCode! >= 500
          ? serverUnavailable
          : serverUnreachable;
    }
    if (_isTechnical(error.message)) return genericFailure;
    return error.message;
  }

  static String forUnknown(Object error) {
    if (error is MonPeyaApiException) return forException(error);
    if (_looksLikeNetworkFailure(error)) return serverUnreachable;
    return genericFailure;
  }

  static String dialogTitleFor(Object error) {
    if (error is MonPeyaApiException && _isInfrastructure(error)) {
      return dialogTitleUnavailable;
    }
    if (_looksLikeNetworkFailure(error)) return dialogTitleUnavailable;
    return dialogTitleError;
  }

  static bool shouldShowModal(Object error) {
    if (error is MonPeyaApiException) {
      return _isInfrastructure(error) || _isTechnical(error.message);
    }
    return _looksLikeNetworkFailure(error);
  }

  static bool _isInfrastructure(MonPeyaApiException error) {
    final code = error.statusCode;
    if (code != null && code >= 500) return true;
    final lower = error.message.toLowerCase();
    return lower.contains('ne répond pas') ||
        lower.contains('impossible de joindre') ||
        lower.contains('connexion impossible') ||
        lower.contains('timeout') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup');
  }

  static bool _isAlreadyFriendly(String message) {
    final lower = message.toLowerCase();
    return lower.contains('serveur mon peya') ||
        lower.contains('token expir') ||
        lower.contains('session requise') ||
        lower.contains('déplafonn') ||
        lower.contains('veuillez réessayer');
  }

  static bool _isTechnical(String message) {
    final lower = message.toLowerCase();
    return lower.contains('internal server error') ||
        lower.contains('exception') ||
        lower.contains('stacktrace') ||
        lower.contains('nullpointer') ||
        lower.contains('sql') ||
        lower.contains('org.') ||
        lower.contains('java.') ||
        lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        RegExp(r'\b\d{3}\b').hasMatch(lower) &&
            (lower.contains('error') || lower.contains('http'));
  }

  static bool _looksLikeNetworkFailure(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('timeoutexception') ||
        msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable');
  }
}
