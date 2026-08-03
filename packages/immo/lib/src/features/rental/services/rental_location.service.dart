import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Result of asking for device location for “Around you”.
class RentalUserLocation {
  const RentalUserLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

enum RentalLocationStatus {
  ok,
  serviceDisabled,
  denied,
  deniedForever,
  error,
}

class RentalLocationResult {
  const RentalLocationResult._({
    required this.status,
    this.location,
    this.message,
  });

  factory RentalLocationResult.ok(RentalUserLocation location) =>
      RentalLocationResult._(
        status: RentalLocationStatus.ok,
        location: location,
      );

  factory RentalLocationResult.fail(
    RentalLocationStatus status, [
    String? message,
  ]) =>
      RentalLocationResult._(status: status, message: message);

  final RentalLocationStatus status;
  final RentalUserLocation? location;
  final String? message;

  bool get hasLocation =>
      status == RentalLocationStatus.ok && location != null;
}

/// Requests permission and reads the current position for nearby listings.
abstract final class RentalLocationService {
  /// Radius used for “Around you” (500 meters).
  static const nearbyRadiusMeters = 500.0;

  static RentalUserLocation? _cached;
  static DateTime? _cachedAt;

  static RentalUserLocation? get cached => _cached;

  static bool get _cacheFresh {
    final at = _cachedAt;
    if (_cached == null || at == null) return false;
    return DateTime.now().difference(at) < const Duration(minutes: 2);
  }

  static Future<bool> needsPermissionRequest() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine;
  }

  static Future<bool> hasGrantedPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Shows the system permission dialog when allowed by the OS.
  static Future<LocationPermission> requestOsPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  static Future<RentalLocationResult> requestAndGetPosition({
    bool forceRefresh = false,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Still usable if we have a recent cache.
        if (_cached != null) return RentalLocationResult.ok(_cached!);
        return RentalLocationResult.fail(
          RentalLocationStatus.serviceDisabled,
          'Activez le GPS / la localisation de votre téléphone, puis réessayez.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (_cached != null) return RentalLocationResult.ok(_cached!);
        return RentalLocationResult.fail(
          RentalLocationStatus.denied,
          'Autorisez l’accès à votre position pour afficher les biens autour de vous.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        if (_cached != null) return RentalLocationResult.ok(_cached!);
        return RentalLocationResult.fail(
          RentalLocationStatus.deniedForever,
          'La localisation est bloquée pour Mon Peya. Ouvrez les réglages et activez-la.',
        );
      }

      if (!forceRefresh && _cacheFresh) {
        return RentalLocationResult.ok(_cached!);
      }

      final position = await _resolvePosition(preferFresh: forceRefresh);
      if (position == null) {
        if (_cached != null) return RentalLocationResult.ok(_cached!);
        return RentalLocationResult.fail(
          RentalLocationStatus.error,
          'Impossible d’obtenir votre position pour le moment. Vérifiez que le GPS est activé (extérieur / mode haute précision) et réessayez.',
        );
      }

      final loc = RentalUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _cached = loc;
      _cachedAt = DateTime.now();
      return RentalLocationResult.ok(loc);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Immo] location error: $e\n$st');
      }
      if (_cached != null) return RentalLocationResult.ok(_cached!);
      return RentalLocationResult.fail(
        RentalLocationStatus.error,
        'Impossible d’obtenir votre position pour le moment. Vérifiez que le GPS est activé et réessayez.',
      );
    }
  }

  /// Fast path: last-known → stream → current, never relying on geolocator timeLimit
  /// (that throws [TimeoutException] and feels like a hard failure).
  static Future<Position?> _resolvePosition({required bool preferFresh}) async {
    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
      if (kDebugMode && lastKnown != null) {
        debugPrint(
          '[Immo] lastKnown: ${lastKnown.latitude}, ${lastKnown.longitude}',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Immo] getLastKnownPosition failed: $e');
    }

    // Instant UX when we already have a fix and don't force a refresh.
    if (!preferFresh && lastKnown != null) {
      // Refine in background when possible.
      unawaited(_refineInBackground());
      return lastKnown;
    }

    final fresh = await _fetchFreshPosition();
    if (fresh != null) return fresh;

    return lastKnown;
  }

  static Future<Position?> _fetchFreshPosition() async {
    // 1) First event from the position stream (often faster than getCurrentPosition).
    try {
      final pos = await Geolocator.getPositionStream(
        locationSettings: _settings(accuracy: LocationAccuracy.low),
      ).first.timeout(const Duration(seconds: 8));
      if (kDebugMode) {
        debugPrint('[Immo] stream fix: ${pos.latitude}, ${pos.longitude}');
      }
      return pos;
    } catch (e) {
      if (kDebugMode) debugPrint('[Immo] position stream failed: $e');
    }

    // 2) getCurrentPosition without plugin timeLimit — we apply our own timeout.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _settings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 12));
      if (kDebugMode) {
        debugPrint('[Immo] current low: ${pos.latitude}, ${pos.longitude}');
      }
      return pos;
    } catch (e) {
      if (kDebugMode) debugPrint('[Immo] getCurrentPosition low failed: $e');
    }

    // 3) Android LocationManager fallback.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _settings(
          accuracy: LocationAccuracy.lowest,
          forceAndroidLocationManager: true,
        ),
      ).timeout(const Duration(seconds: 12));
      if (kDebugMode) {
        debugPrint('[Immo] current LM: ${pos.latitude}, ${pos.longitude}');
      }
      return pos;
    } catch (e) {
      if (kDebugMode) debugPrint('[Immo] getCurrentPosition LM failed: $e');
    }

    return null;
  }

  static Future<void> _refineInBackground() async {
    try {
      final pos = await _fetchFreshPosition();
      if (pos == null) return;
      _cached = RentalUserLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _cachedAt = DateTime.now();
    } catch (_) {}
  }

  /// No [LocationSettings.timeLimit] — it surfaces as TimeoutException from the plugin.
  static LocationSettings _settings({
    required LocationAccuracy accuracy,
    bool forceAndroidLocationManager = false,
  }) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        forceLocationManager: forceAndroidLocationManager,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.other,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: false,
      );
    }
    return LocationSettings(accuracy: accuracy);
  }

  static double distanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();
}
