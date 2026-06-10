import '../models/immo_api_response.dart';
import 'immo_api_client.dart';

/// Resolves `codePaysId` for property creation — mirrors rental-app country detection.
class ImmoCountryService {
  ImmoCountryService({ImmoApiClient? client}) : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;
  List<Map<String, dynamic>>? _cache;

  static const _ciNames = [
    "côte d'ivoire",
    'cote d\'ivoire',
    'ivory coast',
    'ivoire',
  ];

  Future<String> resolveCountryId({double? latitude, double? longitude}) async {
    final countries = await _fetchCountries();
    if (countries.isEmpty) {
      throw Exception('Impossible de déterminer le pays.');
    }

    if (latitude != null && longitude != null) {
      final matched = await _matchByCoordinates(countries, latitude, longitude);
      if (matched != null) return matched;
    }

    final ci = countries.cast<Map<String, dynamic>?>().firstWhere(
          (c) {
            if (c == null) return false;
            final name = (c['libelle'] ?? c['nom'] ?? '').toString().toLowerCase();
            final code = (c['code'] ?? c['iso'] ?? c['codeIso'] ?? '')
                .toString()
                .toUpperCase();
            return code == 'CI' || _ciNames.any((n) => name.contains(n));
          },
          orElse: () => null,
        );
    if (ci != null) {
      return (ci['codePaysId'] ?? ci['id']).toString();
    }

    return (countries.first['codePaysId'] ?? countries.first['id']).toString();
  }

  Future<List<Map<String, dynamic>>> _fetchCountries() async {
    if (_cache != null) return _cache!;

    final response = await _client.postJson(
      '/api/codePays/getByCriteria',
      body: {'data': null},
    );

    if (!response.success || response.data == null) return const [];

    final envelope = _asEnvelope(response.data!);
    _cache = envelope.items;
    return _cache!;
  }

  Future<String?> _matchByCoordinates(
    List<Map<String, dynamic>> countries,
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$latitude&lon=$longitude&addressdetails=1',
      );
      final response = await _client.getBody(uri.toString());
      if (!response.success || response.data is! Map) return null;

      final address = (response.data as Map)['address'];
      if (address is! Map) return null;

      final detectedCountry =
          (address['country'] as String?)?.toLowerCase() ?? '';
      final countryCode =
          (address['country_code'] as String?)?.toUpperCase() ?? '';

      for (final c in countries) {
        final name = (c['libelle'] ?? c['nom'] ?? '').toString().toLowerCase();
        final iso =
            (c['code'] ?? c['iso'] ?? c['codeIso'] ?? '').toString().toUpperCase();

        if (countryCode.isNotEmpty && iso == countryCode) {
          return (c['codePaysId'] ?? c['id']).toString();
        }
        if (detectedCountry.isNotEmpty && name.contains(detectedCountry)) {
          return (c['codePaysId'] ?? c['id']).toString();
        }
        if (countryCode == 'CI' && _ciNames.any((n) => name.contains(n))) {
          return (c['codePaysId'] ?? c['id']).toString();
        }
      }
    } catch (_) {
      // Geocoding is best-effort; fall back to default country.
    }
    return null;
  }

  ImmoBackendEnvelope _asEnvelope(Map<String, dynamic> data) {
    if (data.containsKey('hasError') || data.containsKey('items')) {
      return ImmoBackendEnvelope.fromJson(data);
    }
    if (data['data'] is Map) {
      return ImmoBackendEnvelope.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }
    return const ImmoBackendEnvelope();
  }
}
