import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/immo_api_config.dart';
import 'immo_api_client.dart';

/// Multipart upload to `/api/upload/file` — mirrors rental-app `apiService.uploadFile`.
class ImmoUploadService {
  ImmoUploadService({ImmoApiClient? client}) : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  Future<String?> uploadImagePath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final request = http.MultipartRequest(
      'POST',
      _client.resolve('/api/upload/file'),
    );

    final token = _client.authToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'photo.jpg',
      ),
    );

    final streamed = await request.send().timeout(
      const Duration(milliseconds: ImmoApiConfig.timeoutMs),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    if (response.body.isEmpty) return null;

    final decoded = _client.decodeJson(response.body);
    if (decoded is! Map) return null;

    final map = Map<String, dynamic>.from(decoded);
    if (map['hasError'] == true) return null;

    final item = map['item'];
    if (item is String && item.isNotEmpty) return item;
    if (item is Map) {
      final url = item['url'] ?? item['item'];
      if (url is String && url.isNotEmpty) return url;
    }

    final url = map['url'];
    if (url is String && url.isNotEmpty) return url;

    return null;
  }

  Future<List<String>> uploadImagePaths(List<String> paths) async {
    final urls = <String>[];
    for (final path in paths) {
      final url = await uploadImagePath(path);
      if (url != null) urls.add(url);
    }
    return urls;
  }
}
