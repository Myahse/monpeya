import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/mock_events.dart';
import '../models/billetterie_event.dart';

/// API client — mirrors NTERI `api.ts` (mock fallback when backend unavailable).
class BilletterieApiConfig {
  static const defaultBaseUrl = String.fromEnvironment(
    'BILLETTERIE_API_URL',
    defaultValue: 'http://10.0.2.2:8089/api/billetterie-electronique',
  );

  static String get baseUrl => defaultBaseUrl;
}

class BilletterieApiService {
  BilletterieApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<BilletterieEvent>> getEvents() async {
    try {
      final response = await _client
          .get(Uri.parse('${BilletterieApiConfig.baseUrl}/events'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .whereType<Map>()
              .map((e) => BilletterieEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {
      // Fall back to mock data like the Expo app.
    }
    return mockBilletterieEvents;
  }

  Future<BilletterieEvent?> getEvent(String id) async {
    try {
      final response = await _client
          .get(Uri.parse('${BilletterieApiConfig.baseUrl}/events/$id'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return BilletterieEvent.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}
    return mockBilletterieEvents.cast<BilletterieEvent?>().firstWhere(
          (e) => e?.id == id,
          orElse: () => null,
        );
  }
}
