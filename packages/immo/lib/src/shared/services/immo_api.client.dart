import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:immo/src/shared/config/immo_api.config.dart';
import 'package:immo/src/shared/models/immo_api.response.dart';

/// HTTP client for Mr Immo Spring Boot API (mirrors rental-app `apiService.ts`).
class ImmoApiClient {
  ImmoApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? ImmoApiConfig.baseUrl,
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? _authToken;

  String? get authToken => _authToken;

  void setAuthToken(String? token) => _authToken = token;

  Uri resolve(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized');
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
      ...?extra,
    };
  }

  Future<ImmoApiResponse<dynamic>> getBody(String path) async {
    try {
      final response = await _http
          .get(resolve(path), headers: _headers())
          .timeout(const Duration(milliseconds: ImmoApiConfig.timeoutMs));

      return _parseBody(response);
    } catch (e) {
      return ImmoApiResponse(success: false, error: e.toString());
    }
  }

  Future<ImmoApiResponse<Map<String, dynamic>>> getJson(String path) async {
    try {
      final response = await _http
          .get(resolve(path), headers: _headers())
          .timeout(const Duration(milliseconds: ImmoApiConfig.timeoutMs));

      return _parseResponse(response);
    } catch (e) {
      return ImmoApiResponse(success: false, error: e.toString());
    }
  }

  Future<ImmoApiResponse<Map<String, dynamic>>> postJson(
    String path, {
    Object? body,
    Duration? timeout,
  }) async {
    try {
      final response = await _http
          .post(
            resolve(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout ?? const Duration(milliseconds: ImmoApiConfig.timeoutMs));

      return _parseResponse(response);
    } catch (e) {
      return ImmoApiResponse(success: false, error: e.toString());
    }
  }

  /// POST that treats HTTP 2xx as success even when the body is plain text
  /// (e.g. `/api/favoris/{user}/{bien}` → `"Favorite added successfully"`).
  Future<ImmoApiResponse<void>> postOk(
    String path, {
    Object? body,
    Duration? timeout,
  }) async {
    try {
      final response = await _http
          .post(
            resolve(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout ?? const Duration(milliseconds: ImmoApiConfig.timeoutMs));
      return _parseOk(response);
    } catch (e) {
      return ImmoApiResponse(success: false, error: e.toString());
    }
  }

  Future<ImmoApiResponse<Map<String, dynamic>>> deleteJson(String path) async {
    try {
      final response = await _http
          .delete(resolve(path), headers: _headers())
          .timeout(const Duration(milliseconds: ImmoApiConfig.timeoutMs));

      return _parseResponse(response);
    } catch (e) {
      return ImmoApiResponse(success: false, error: e.toString());
    }
  }

  /// DELETE that treats HTTP 2xx as success even when the body is plain text.
  Future<ImmoApiResponse<void>> deleteOk(String path) async {
    try {
      final response = await _http
          .delete(resolve(path), headers: _headers())
          .timeout(const Duration(milliseconds: ImmoApiConfig.timeoutMs));
      return _parseOk(response);
    } catch (e) {
      return ImmoApiResponse(success: false, error: e.toString());
    }
  }

  ImmoApiResponse<dynamic> _parseBody(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      data = _tryDecode(response.body) ?? response.body;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['message'] as String? ?? data['error'] as String? ?? 'HTTP ${response.statusCode}')
          : (data is String && data.isNotEmpty
              ? data
              : 'HTTP ${response.statusCode}');
      return ImmoApiResponse(success: false, error: message, data: data);
    }

    return ImmoApiResponse(success: true, data: data);
  }

  ImmoApiResponse<Map<String, dynamic>> _parseResponse(http.Response response) {
    Map<String, dynamic>? data;
    final decoded = response.body.isNotEmpty ? _tryDecode(response.body) : null;
    if (decoded is Map<String, dynamic>) {
      data = decoded;
    } else if (decoded is Map) {
      data = Map<String, dynamic>.from(decoded);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data?['message'] as String? ??
          data?['error'] as String? ??
          (decoded is String && decoded.isNotEmpty
              ? decoded
              : 'HTTP ${response.statusCode}');
      return ImmoApiResponse(success: false, error: message, data: data);
    }

    return ImmoApiResponse(success: true, data: data);
  }

  ImmoApiResponse<void> _parseOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return const ImmoApiResponse(success: true);
    }
    final decoded = response.body.isNotEmpty ? _tryDecode(response.body) : null;
    final message = decoded is Map
        ? (decoded['message'] as String? ??
            decoded['error'] as String? ??
            'HTTP ${response.statusCode}')
        : (response.body.isNotEmpty
            ? response.body
            : 'HTTP ${response.statusCode}');
    return ImmoApiResponse(success: false, error: message);
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  dynamic decodeJson(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }
}
