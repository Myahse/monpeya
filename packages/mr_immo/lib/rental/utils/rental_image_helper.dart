import 'dart:convert';

/// Resolves property image URLs from backend fields (mirrors ListingsScreen.tsx).
String? resolvePropertyImageUrl(
  Map<String, dynamic> raw, {
  String? apiHostForLocalhost,
}) {
  String? imageUri;

  final images = raw['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first is Map) {
      imageUri = first['url'] as String?;
    } else if (first is String) {
      imageUri = first;
    }
  }

  final photos = raw['photos'];
  if (imageUri == null && photos is List && photos.isNotEmpty) {
    final first = photos.first;
    if (first is Map) {
      imageUri = first['url'] as String?;
    } else if (first is String) {
      imageUri = first;
    }
  }

  final photo = raw['photo'];
  if (imageUri == null && photo != null) {
    if (photo is String) {
      try {
        final parsed = jsonDecode(photo);
        if (parsed is List && parsed.isNotEmpty) {
          for (final url in parsed) {
            if (url is String && _isValidImageUrl(url)) {
              imageUri = url;
              break;
            }
          }
        }
      } catch (_) {
        if (_isValidImageUrl(photo)) imageUri = photo;
      }
    }
  }

  if (imageUri == null) return null;
  return _fixLocalhost(imageUri, apiHostForLocalhost);
}

bool _isValidImageUrl(String url) {
  return url.startsWith('http://') ||
      url.startsWith('https://') ||
      url.startsWith('/');
}

String _fixLocalhost(String url, String? apiHostForLocalhost) {
  if (!url.contains('localhost') || apiHostForLocalhost == null) return url;
  final host = Uri.tryParse(apiHostForLocalhost)?.host;
  if (host == null || host == 'localhost') return url;
  return url
      .replaceAll('localhost:8081', '$host:8081')
      .replaceAll('localhost:8080', '$host:8081');
}
