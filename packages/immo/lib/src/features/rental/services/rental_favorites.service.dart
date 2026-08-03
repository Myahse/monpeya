import 'package:immo/src/features/rental/config/rental_api.endpoints.dart';
import 'package:immo/src/features/rental/data/rental_mock_properties.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

/// Favorites API — `/api/favoris/{userId}/…` (Mr Immo Spring Boot).
class RentalFavoritesService {
  RentalFavoritesService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;
  final RentalDataCache _cache = RentalDataCache.instance;

  Future<List<RentalProperty>> fetchFavorites(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (userId.isEmpty) return const [];

    if (!forceRefresh) {
      final cached = _cache.favoritesIfFresh(userId);
      if (cached != null) return cached;
    }

    final response =
        await _client.getBody('${RentalApiEndpoints.favorites}/$userId');
    if (!response.success) {
      throw Exception(response.error ?? 'Impossible de charger les favoris');
    }

    final items = _extractPropertyMaps(response.data);
    final mapped = items
        .map((e) => RentalProperty.fromBackend(e, apiBaseUrl: _client.baseUrl))
        .where((p) => p.id.isNotEmpty)
        .toList(growable: false);
    final enriched = RentalMockProperties.enrichMissingImages(mapped);
    _cache.putFavorites(userId, enriched);
    return enriched;
  }

  Future<Set<String>> fetchFavoriteIds(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _cache.favoriteIdsIfFresh(userId);
      if (cached != null) return cached;
    }
    final items = await fetchFavorites(userId, forceRefresh: forceRefresh);
    return items.map((p) => p.id).toSet();
  }

  Future<void> addFavorite({
    required String userId,
    required String propertyId,
  }) async {
    final response = await _client.postOk(
      '${RentalApiEndpoints.favorites}/$userId/$propertyId',
    );
    if (!response.success) {
      throw Exception(response.error ?? 'Impossible d’ajouter aux favoris');
    }
    _cache.markFavorite(
      userId: userId,
      propertyId: propertyId,
      property: _cache.propertyById(propertyId),
    );
  }

  Future<void> removeFavorite({
    required String userId,
    required String propertyId,
  }) async {
    final response = await _client.deleteOk(
      '${RentalApiEndpoints.favorites}/$userId/$propertyId',
    );
    if (!response.success) {
      throw Exception(response.error ?? 'Impossible de retirer des favoris');
    }
    _cache.unmarkFavorite(userId: userId, propertyId: propertyId);
  }

  Future<bool> isFavorited({
    required String userId,
    required String propertyId,
  }) async {
    if (userId.isEmpty || propertyId.isEmpty) return false;

    final cachedIds = _cache.favoriteIdsIfFresh(userId);
    if (cachedIds != null) return cachedIds.contains(propertyId);

    final response = await _client.getBody(
      '${RentalApiEndpoints.favorites}/$userId/$propertyId/check',
    );
    if (!response.success) return false;
    final raw = response.data;
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  List<Map<String, dynamic>> _extractPropertyMaps(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map(_asPropertyMap)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final items = map['items'];
      if (items is List) {
        return items
            .map(_asPropertyMap)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
      final asProperty = _asPropertyMap(map);
      return asProperty == null ? const [] : [asProperty];
    }
    return const [];
  }

  Map<String, dynamic>? _asPropertyMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    // Some payloads wrap the bien: { biens: {...} } or { bien: {...} }.
    final nested = map['biens'] ?? map['bien'] ?? map['property'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return map;
  }
}
