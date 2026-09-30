import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/storage/constants/prefs.keys.dart';

/// Noms de services connus (clés racine du JSON métadonnées).
abstract class ServiceMetaNames {
  static const leadway = 'leadway';
  static const sim = 'sim';
  static const immo = 'immo';
  static const peyapay = 'peyapay';
  static const billetterie = 'billetterie';
}

/// Clés de métadonnées fréquentes.
abstract class ServiceMetaKeys {
  static const customerId = 'customerId';
  static const subscriptionRef = 'subscriptionRef';
  static const phone = 'phone';
}

/// Stockage global des métadonnées par service (JSON dans SharedPreferences).
///
/// **Vit uniquement dans l'app** (`app/lib/...`). Les packages (Leadway, etc.)
/// n'y accèdent pas directement : l'app injecte `set` / `get` via les host bridges.
///
/// Usage app :
/// ```dart
/// await ServiceMetadataStore.set(ServiceMetaNames.leadway, ServiceMetaKeys.customerId, id);
/// final id = await ServiceMetadataStore.get(ServiceMetaNames.leadway, ServiceMetaKeys.customerId);
/// ```
///
/// Exemple de payload :
/// ```json
/// {
///   "leadway": { "customerId": "CUST-1", "phone": "0707070707" },
///   "immo": { "userId": "…" }
/// }
/// ```
class ServiceMetadataStore {
  ServiceMetadataStore._();

  /// Enregistre une métadonnée pour un service.
  static Future<void> set(String service, String key, String value) async {
    final normalizedService = service.trim();
    final normalizedKey = key.trim();
    if (normalizedService.isEmpty || normalizedKey.isEmpty) return;

    final root = await _readRoot();
    final serviceMap = Map<String, dynamic>.from(
      root[normalizedService] is Map
          ? Map<String, dynamic>.from(root[normalizedService] as Map)
          : <String, dynamic>{},
    );
    serviceMap[normalizedKey] = value;
    root[normalizedService] = serviceMap;
    await _writeRoot(root);
  }

  /// Récupère une métadonnée (ou `null` si absente).
  static Future<String?> get(String service, String key) async {
    final normalizedService = service.trim();
    final normalizedKey = key.trim();
    if (normalizedService.isEmpty || normalizedKey.isEmpty) return null;

    final root = await _readRoot();
    final serviceData = root[normalizedService];
    if (serviceData is! Map) return null;
    final value = serviceData[normalizedKey];
    if (value == null) return null;
    final asString = value.toString();
    return asString.isEmpty ? null : asString;
  }

  /// Toutes les métadonnées d’un service (valeurs en String).
  static Future<Map<String, String>> getAll(String service) async {
    final normalizedService = service.trim();
    if (normalizedService.isEmpty) return {};

    final root = await _readRoot();
    final serviceData = root[normalizedService];
    if (serviceData is! Map) return {};

    final out = <String, String>{};
    for (final entry in serviceData.entries) {
      final v = entry.value?.toString() ?? '';
      if (v.isNotEmpty) out[entry.key.toString()] = v;
    }
    return out;
  }

  /// Supprime une clé pour un service.
  static Future<void> remove(String service, String key) async {
    final normalizedService = service.trim();
    final normalizedKey = key.trim();
    if (normalizedService.isEmpty || normalizedKey.isEmpty) return;

    final root = await _readRoot();
    final serviceData = root[normalizedService];
    if (serviceData is! Map) return;

    final serviceMap = Map<String, dynamic>.from(serviceData);
    serviceMap.remove(normalizedKey);
    if (serviceMap.isEmpty) {
      root.remove(normalizedService);
    } else {
      root[normalizedService] = serviceMap;
    }
    await _writeRoot(root);
  }

  /// Efface toutes les métadonnées d’un service.
  static Future<void> clearService(String service) async {
    final normalizedService = service.trim();
    if (normalizedService.isEmpty) return;
    final root = await _readRoot();
    root.remove(normalizedService);
    await _writeRoot(root);
  }

  static Future<Map<String, dynamic>> _readRoot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefsKeys.serviceMetadata);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  static Future<void> _writeRoot(Map<String, dynamic> root) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.serviceMetadata, jsonEncode(root));
  }
}
