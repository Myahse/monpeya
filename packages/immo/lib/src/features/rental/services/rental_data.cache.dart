import 'package:flutter/foundation.dart';

import 'package:immo/src/features/rental/models/rental.property.dart';

/// In-memory cache for rental listings / favorites so UI avoids redundant HTTP.
class RentalDataCache extends ChangeNotifier {
  RentalDataCache._();

  static final RentalDataCache instance = RentalDataCache._();

  static const Duration defaultTtl = Duration(minutes: 5);

  List<RentalProperty>? _available;
  DateTime? _availableAt;

  final Map<String, RentalProperty> _byId = {};
  final Map<String, DateTime> _byIdAt = {};

  final Map<String, List<RentalProperty>> _favoritesByUser = {};
  final Map<String, DateTime> _favoritesAt = {};
  final Map<String, Set<String>> _favoriteIdsByUser = {};

  Duration ttl = defaultTtl;

  List<RentalProperty>? get available =>
      _available == null ? null : List.unmodifiable(_available!);

  List<RentalProperty>? get availableIfFresh {
    if (!_isFresh(_availableAt)) return null;
    return available;
  }

  RentalProperty? propertyById(String id, {bool requireFresh = false}) {
    final key = id.trim();
    if (key.isEmpty) return null;
    final hit = _byId[key];
    if (hit == null) return null;
    if (requireFresh && !_isFresh(_byIdAt[key])) return null;
    return hit;
  }

  List<RentalProperty>? favoritesIfFresh(String userId) {
    final key = userId.trim();
    if (key.isEmpty) return null;
    if (!_isFresh(_favoritesAt[key])) return null;
    final list = _favoritesByUser[key];
    return list == null ? null : List.unmodifiable(list);
  }

  
  List<RentalProperty>? favorites(String userId) {
    final key = userId.trim();
    if (key.isEmpty) return null;
    final list = _favoritesByUser[key];
    return list == null ? null : List.unmodifiable(list);
  }

  Set<String>? favoriteIdsIfFresh(String userId) {
    final key = userId.trim();
    if (key.isEmpty) return null;
    if (!_isFresh(_favoritesAt[key])) return null;
    final ids = _favoriteIdsByUser[key];
    return ids == null ? null : Set.unmodifiable(ids);
  }

  void putAvailable(List<RentalProperty> items) {
    _available = List.unmodifiable(items);
    _availableAt = DateTime.now();
    for (final p in items) {
      _putProperty(p, notify: false);
    }
    notifyListeners();
  }

  void putProperty(RentalProperty property) {
    _putProperty(property, notify: true);
  }

  void upsertIntoAvailable(RentalProperty property) {
    _putProperty(property, notify: false);
    final current = [...?_available];
    final idx = current.indexWhere((p) => p.id == property.id);
    if (property.isAvailableForRent) {
      if (idx >= 0) {
        current[idx] = property;
      } else {
        current.insert(0, property);
      }
    } else if (idx >= 0) {
      current.removeAt(idx);
    }
    _available = List.unmodifiable(current);
    _availableAt = DateTime.now();
    notifyListeners();
  }

  void removeProperty(String id) {
    final key = id.trim();
    if (key.isEmpty) return;
    _byId.remove(key);
    _byIdAt.remove(key);
    if (_available != null) {
      _available = List.unmodifiable(
        _available!.where((p) => p.id != key),
      );
      _availableAt = DateTime.now();
    }
    for (final entry in _favoritesByUser.entries.toList()) {
      final next = entry.value.where((p) => p.id != key).toList(growable: false);
      _favoritesByUser[entry.key] = next;
      _favoriteIdsByUser[entry.key] = next.map((p) => p.id).toSet();
      _favoritesAt[entry.key] = DateTime.now();
    }
    notifyListeners();
  }

  void putFavorites(String userId, List<RentalProperty> items) {
    final key = userId.trim();
    if (key.isEmpty) return;
    final list = List<RentalProperty>.unmodifiable(items);
    _favoritesByUser[key] = list;
    _favoriteIdsByUser[key] = list.map((p) => p.id).toSet();
    _favoritesAt[key] = DateTime.now();
    for (final p in list) {
      _putProperty(p, notify: false);
    }
    notifyListeners();
  }

  void markFavorite({
    required String userId,
    required String propertyId,
    RentalProperty? property,
  }) {
    final key = userId.trim();
    final pid = propertyId.trim();
    if (key.isEmpty || pid.isEmpty) return;

    final ids = {...?_favoriteIdsByUser[key], pid};
    _favoriteIdsByUser[key] = ids;

    final current = [...?_favoritesByUser[key]];
    if (!current.any((p) => p.id == pid)) {
      final prop = property ?? _byId[pid];
      if (prop != null) current.insert(0, prop);
    }
    _favoritesByUser[key] = List.unmodifiable(current);
    _favoritesAt[key] = DateTime.now();
    notifyListeners();
  }

  void unmarkFavorite({
    required String userId,
    required String propertyId,
  }) {
    final key = userId.trim();
    final pid = propertyId.trim();
    if (key.isEmpty || pid.isEmpty) return;

    final ids = {...?_favoriteIdsByUser[key]}..remove(pid);
    _favoriteIdsByUser[key] = ids;
    _favoritesByUser[key] = List.unmodifiable(
      (_favoritesByUser[key] ?? const []).where((p) => p.id != pid),
    );
    _favoritesAt[key] = DateTime.now();
    notifyListeners();
  }

  void invalidateAvailable() {
    _availableAt = null;
    notifyListeners();
  }

  void invalidateFavorites([String? userId]) {
    final key = userId?.trim();
    if (key == null || key.isEmpty) {
      _favoritesAt.clear();
    } else {
      _favoritesAt.remove(key);
    }
    notifyListeners();
  }

  void invalidateAll() {
    _available = null;
    _availableAt = null;
    _byId.clear();
    _byIdAt.clear();
    _favoritesByUser.clear();
    _favoritesAt.clear();
    _favoriteIdsByUser.clear();
    notifyListeners();
  }

  void _putProperty(RentalProperty property, {required bool notify}) {
    if (property.id.isEmpty) return;
    _byId[property.id] = property;
    _byIdAt[property.id] = DateTime.now();
    if (notify) notifyListeners();
  }

  bool _isFresh(DateTime? at) {
    if (at == null) return false;
    return DateTime.now().difference(at) <= ttl;
  }
}
