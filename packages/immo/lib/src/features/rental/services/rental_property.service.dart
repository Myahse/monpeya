import 'package:immo/src/shared/models/immo_api.response.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/shared/services/immo_country.service.dart';
import 'package:immo/src/shared/services/immo_upload.service.dart';
import 'package:immo/src/features/rental/config/rental_api.endpoints.dart';
import 'package:immo/src/features/rental/data/rental_mock_properties.dart';
import 'package:immo/src/features/rental/models/create_listing.draft.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';

/// Properties API — port from rental-app `propertyService.ts`.
class RentalPropertyService {
  RentalPropertyService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient(),
        _upload = ImmoUploadService(client: client ?? ImmoApiClient()),
        _countries = ImmoCountryService(client: client ?? ImmoApiClient());

  final ImmoApiClient _client;
  final ImmoUploadService _upload;
  final ImmoCountryService _countries;
  final RentalDataCache _cache = RentalDataCache.instance;

  Future<List<RentalProperty>> fetchProperties({
    String? search,
    String? city,
    String? ownerUserId,
  }) async {
    final criteria = <String, dynamic>{};
    if (search != null && search.isNotEmpty) criteria['nom'] = search;
    if (city != null && city.isNotEmpty) criteria['ville'] = city;
    if (ownerUserId != null && ownerUserId.isNotEmpty) {
      criteria['utilisateursId'] = ownerUserId;
    }

    final response = await _client.postJson(
      RentalApiEndpoints.listProperties,
      body: {'data': criteria.isEmpty ? null : criteria},
    );

    final items = _extractItems(response);
    final mapped = items
        .map((e) => RentalProperty.fromBackend(e, apiBaseUrl: _client.baseUrl))
        .where((p) => p.id.isNotEmpty)
        .toList();
    for (final p in mapped) {
      _cache.putProperty(p);
    }
    return mapped;
  }

  
  Future<List<RentalProperty>> fetchAvailableProperties({
    String? search,
    String? city,
    bool forceRefresh = false,
  }) async {
    final hasFilter =
        (search != null && search.isNotEmpty) || (city != null && city.isNotEmpty);

    if (!hasFilter && !forceRefresh) {
      final cached = _cache.availableIfFresh;
      if (cached != null) return cached;
    }

    if (!hasFilter) {
      final response = await _client.getJson(RentalApiEndpoints.availableProperties);
      if (response.success) {
        final items = _extractItems(response);
        if (items.isNotEmpty || response.data != null) {
          final mapped = items
              .map((e) => RentalProperty.fromBackend(e, apiBaseUrl: _client.baseUrl))
              .where((p) => p.id.isNotEmpty)
              .toList(growable: false);
          if (mapped.isNotEmpty) {
            final enriched = RentalMockProperties.enrichMissingImages(mapped);
            _cache.putAvailable(enriched);
            return enriched;
          }
        }
      }
    }

    final all = await fetchProperties(search: search, city: city);
    final available = all.where((p) => p.isAvailableForRent).toList(growable: false);
    if (available.isNotEmpty) {
      final enriched = RentalMockProperties.enrichMissingImages(available);
      if (!hasFilter) _cache.putAvailable(enriched);
      return enriched;
    }

    return RentalMockProperties.samples;
  }

  /// Properties owned by the connected landlord.
  Future<List<RentalProperty>> fetchMyProperties({String? ownerUserId}) =>
      fetchProperties(ownerUserId: ownerUserId);

  Future<RentalProperty?> fetchPropertyById(
    String id, {
    bool forceRefresh = false,
  }) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    final mock = RentalMockProperties.byId(trimmed);
    if (mock != null) return mock;

    if (!forceRefresh) {
      final fresh = _cache.propertyById(trimmed, requireFresh: true);
      if (fresh != null) return fresh;
    }

    final fromCriteria = await _fetchPropertyByCriteria(trimmed);
    if (fromCriteria != null) {
      final enriched =
          RentalMockProperties.enrichMissingImages([fromCriteria]).first;
      _cache.putProperty(enriched);
      return enriched;
    }

    final fromPublic = await _fetchPropertyFromPublicEndpoint(trimmed);
    if (fromPublic == null) {
      return _cache.propertyById(trimmed);
    }
    final enriched =
        RentalMockProperties.enrichMissingImages([fromPublic]).first;
    _cache.putProperty(enriched);
    return enriched;
  }

  Future<RentalProperty?> _fetchPropertyByCriteria(String id) async {
    for (final key in ['biensId', 'id']) {
      final response = await _client.postJson(
        RentalApiEndpoints.listProperties,
        body: {
          'data': {key: id},
        },
      );
      if (!response.success || response.data == null) continue;

      final items = _extractItems(response);
      if (items.isEmpty) continue;

      return RentalProperty.fromBackend(
        items.first,
        apiBaseUrl: _client.baseUrl,
      );
    }
    return null;
  }

  Future<RentalProperty?> _fetchPropertyFromPublicEndpoint(String id) async {
    final response = await _client.getJson('${RentalApiEndpoints.publicProperty}/$id');
    if (!response.success || response.data == null) return null;

    final envelope = _asEnvelope(response.data!);
    if (envelope.hasError) return null;

    Map<String, dynamic>? raw;
    if (envelope.items.isNotEmpty) {
      raw = envelope.items.first;
    } else if (envelope.item != null) {
      raw = envelope.item;
    } else {
      raw = response.data;
    }

    if (raw == null) return null;
    return RentalProperty.fromBackend(raw, apiBaseUrl: _client.baseUrl);
  }

  Future<void> createProperty(
    CreateListingDraft draft, {
    String? utilisateursId,
  }) async {
    final photoUrls = await _upload.uploadImagePaths(draft.photoPaths);
    final codePaysId = await _countries.resolveCountryId(
      latitude: draft.latitude,
      longitude: draft.longitude,
    );

    final response = await _client.postJson(
      RentalApiEndpoints.createProperty,
      body: {
        'data': draft.toCreatePayload(
          utilisateursId: utilisateursId,
          photoUrls: photoUrls,
          codePaysId: codePaysId,
        ),
      },
    );

    if (!response.success) {
      throw Exception(response.error ?? 'Création du bien impossible');
    }

    final data = response.data;
    if (data != null && data['hasError'] == true) {
      final msg = (data['status'] as Map?)?['message'] as String?;
      throw Exception(msg ?? 'Erreur backend');
    }

    // WS will push the new bien; invalidate so next browse hits network if needed.
    _cache.invalidateAvailable();
  }

  List<Map<String, dynamic>> _extractItems(ImmoApiResponse<Map<String, dynamic>> response) {
    if (!response.success || response.data == null) return const [];
    return _asEnvelope(response.data!).items;
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
    return ImmoBackendEnvelope(items: [data]);
  }
}
