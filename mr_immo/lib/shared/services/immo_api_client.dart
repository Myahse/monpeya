import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/immo_api_config.dart';
import '../models/immo_api_response.dart';

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

  ImmoApiResponse<dynamic> _parseBody(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      data = jsonDecode(response.body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['message'] as String? ?? data['error'] as String? ?? 'HTTP ${response.statusCode}')
          : 'HTTP ${response.statusCode}';
      return ImmoApiResponse(success: false, error: message, data: data);
    }

    return ImmoApiResponse(success: true, data: data);
  }

  ImmoApiResponse<Map<String, dynamic>> _parseResponse(http.Response response) {
    Map<String, dynamic>? data;
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data?['message'] as String? ??
          data?['error'] as String? ??
          'HTTP ${response.statusCode}';
      return ImmoApiResponse(success: false, error: message, data: data);
    }

    return ImmoApiResponse(success: true, data: data);
  }

  dynamic decodeJson(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }
}
