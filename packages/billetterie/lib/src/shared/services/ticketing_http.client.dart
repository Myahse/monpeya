import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:billetterie/src/shared/models/ticketing_api.exception.dart';
import 'package:billetterie/src/shared/models/ticketing_api_envelope.model.dart';
import 'package:billetterie/src/shared/config/billetterie_api.config.dart';

/// Shared POST client for Spring Boot ticketing APIs (`{ data }` envelope).
class TicketingHttpClient {
  TicketingHttpClient({
    required String baseUrl,
    http.Client? client,
    this.timeout = BilletterieApiConfig.apiTimeout,
  })  : _baseUrl = _stripTrailingSlash(baseUrl),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<TicketingApiEnvelope<T>> postItems<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) parser,
    required String errorMessage,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _jsonHeaders(),
          body: jsonEncode({'data': data}),
        )
        .timeout(timeout);

    return _parseItemsEnvelope(response, errorMessage: errorMessage, parser: parser);
  }

  Future<void> postSuccess(
    String path, {
    required Map<String, dynamic> data,
    required String errorMessage,
  }) async {
    await postEnvelope(path, data: data, errorMessage: errorMessage);
  }

  Future<T> postForItem<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) parser,
    required String errorMessage,
  }) async {
    final envelope = await postEnvelope(path, data: data, errorMessage: errorMessage);
    final item = envelope.item ??
        (envelope.items != null && envelope.items!.isNotEmpty
            ? envelope.items!.first
            : null);
    if (item == null) {
      throw TicketingApiException(
        message: '$errorMessage (réponse vide)',
        apiCode: envelope.code,
      );
    }
    return parser(item);
  }

  Future<TicketingApiEnvelope<Map<String, dynamic>>> postEnvelope(
    String path, {
    required Map<String, dynamic> data,
    required String errorMessage,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _jsonHeaders(),
          body: jsonEncode({'data': data}),
        )
        .timeout(timeout);

    return _parseEnvelope(response, errorMessage: errorMessage);
  }

  TicketingApiEnvelope<T> _parseItemsEnvelope<T>(
    http.Response response, {
    required String errorMessage,
    required T Function(Map<String, dynamic> json) parser,
  }) {
    final decoded = _decodeBody(response, errorMessage);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TicketingApiException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw TicketingApiException(message: '$errorMessage (format inattendu)');
    }

    final envelope = TicketingApiEnvelope<T>.fromJson(decoded, parser);
    if (envelope.hasError || (envelope.code != null && envelope.code != '800')) {
      throw TicketingApiException(
        message: envelope.message ?? errorMessage,
        statusCode: response.statusCode,
        apiCode: envelope.code,
      );
    }
    return envelope;
  }

  TicketingApiEnvelope<Map<String, dynamic>> _parseEnvelope(
    http.Response response, {
    required String errorMessage,
  }) {
    final decoded = _decodeBody(response, errorMessage);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TicketingApiException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw TicketingApiException(message: '$errorMessage (format inattendu)');
    }

    final envelope = TicketingApiEnvelope<Map<String, dynamic>>.fromJson(
      decoded,
      (json) => json,
    );

    if (envelope.hasError || (envelope.code != null && envelope.code != '800')) {
      throw TicketingApiException(
        message: envelope.message ?? errorMessage,
        statusCode: response.statusCode,
        apiCode: envelope.code,
      );
    }

    return envelope;
  }

  dynamic _decodeBody(http.Response response, String errorMessage) {
    try {
      if (response.body.isEmpty) return const {};
      return jsonDecode(response.body);
    } catch (_) {
      throw TicketingApiException(message: '$errorMessage (réponse invalide)');
    }
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalized');
  }

  Map<String, String> _jsonHeaders() => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static String _stripTrailingSlash(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
