import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:immo/src/features/rental/data/rental_mock_properties.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/services/rental_data.cache.dart';
import 'package:immo/src/features/rental/services/rental_favorites.service.dart';
import 'package:immo/src/features/rental/services/rental_property.service.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/shared/services/immo_realtime.client.dart';

/// Keeps [RentalDataCache] warm via WebSocket events (+ light HTTP fallback).
class RentalRealtimeService {
  RentalRealtimeService._();

  static final RentalRealtimeService instance = RentalRealtimeService._();

  final ImmoRealtimeClient _client = ImmoRealtimeClient();
  final RentalDataCache _cache = RentalDataCache.instance;

  StreamSubscription<ImmoRealtimeEvent>? _sub;
  Timer? _refreshDebounce;
  ImmoApiClient? _apiClient;
  String? _userId;
  bool _started = false;

  bool get isConnected => _client.isConnected;

  void start({
    required ImmoApiClient apiClient,
    String? userId,
  }) {
    _apiClient = apiClient;
    _userId = userId;
    if (_started) return;
    _started = true;
    _sub = _client.events.listen(_onEvent);
    _client.start();
    if (kDebugMode) {
      debugPrint('[RentalRealtime] started → ${_client.url}');
    }
  }

  void updateUserId(String? userId) {
    _userId = userId;
  }

  void stop() {
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    _sub?.cancel();
    _sub = null;
    _client.stop();
    _started = false;
  }

  void dispose() {
    stop();
    _client.dispose();
  }

  void _onEvent(ImmoRealtimeEvent event) {
    if (event.type == 'realtime.connected' || event.type == 'ping') return;
    if (kDebugMode) {
      debugPrint('[RentalRealtime] ${event.type} biensId=${event.biensId}');
    }

    if (event.touchesFavoris) {
      _applyFavoris(event);
    }

    if (event.type.startsWith('bien.')) {
      _applyBien(event);
    }
  }

  void _applyBien(ImmoRealtimeEvent event) {
    final apiBase = _apiClient?.baseUrl;
    if (event.type == 'bien.deleted') {
      final id = event.biensId;
      if (id != null && id.isNotEmpty) {
        _cache.removeProperty(id);
      } else {
        _cache.invalidateAvailable();
        _scheduleAvailableRefresh();
      }
      return;
    }

    final raw = event.item;
    if (raw != null) {
      try {
        final property = RentalProperty.fromBackend(raw, apiBaseUrl: apiBase);
        if (property.id.isNotEmpty) {
          final enriched =
              RentalMockProperties.enrichMissingImages([property]).first;
          _cache.upsertIntoAvailable(enriched);
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[RentalRealtime] failed to parse bien payload: $e');
        }
      }
    }

    _cache.invalidateAvailable();
    _scheduleAvailableRefresh();
  }

  void _applyFavoris(ImmoRealtimeEvent event) {
    final userId = event.userId;
    final biensId = event.biensId;
    final current = _userId;

    if (userId == null ||
        biensId == null ||
        current == null ||
        userId != current) {
      if (userId != null && userId == current) {
        _cache.invalidateFavorites(userId);
      }
      return;
    }

    if (event.type == 'favoris.added') {
      _cache.markFavorite(
        userId: userId,
        propertyId: biensId,
        property: _cache.propertyById(biensId),
      );
    } else if (event.type == 'favoris.removed') {
      _cache.unmarkFavorite(userId: userId, propertyId: biensId);
    } else {
      _cache.invalidateFavorites(userId);
    }

    // Hearts on listing cards may need ids; soft refresh if list was empty.
    final ids = _cache.favoriteIdsIfFresh(userId);
    if (ids == null) {
      _scheduleFavoritesRefresh(userId);
    }
  }

  void _scheduleAvailableRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () async {
      final client = _apiClient;
      if (client == null) return;
      try {
        await RentalPropertyService(client: client)
            .fetchAvailableProperties(forceRefresh: true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[RentalRealtime] available refresh failed: $e');
        }
      }
    });
  }

  void _scheduleFavoritesRefresh(String userId) {
    final client = _apiClient;
    if (client == null) return;
    unawaited(() async {
      try {
        await RentalFavoritesService(client: client)
            .fetchFavorites(userId, forceRefresh: true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[RentalRealtime] favorites refresh failed: $e');
        }
      }
    }());
  }
}
