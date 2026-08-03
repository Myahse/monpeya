import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class BilletterieUserLocation {
  const BilletterieUserLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

enum BilletterieLocationStatus {
  ok,
  serviceDisabled,
  denied,
  deniedForever,
  error,
}

class BilletterieLocationResult {
  const BilletterieLocationResult._({
    required this.status,
    this.location,
    this.message,
  });

  factory BilletterieLocationResult.ok(BilletterieUserLocation location) =>
      BilletterieLocationResult._(
        status: BilletterieLocationStatus.ok,
        location: location,
      );

  factory BilletterieLocationResult.fail(
    BilletterieLocationStatus status, [
    String? message,
  ]) =>
      BilletterieLocationResult._(status: status, message: message);

  final BilletterieLocationStatus status;
  final BilletterieUserLocation? location;
  final String? message;

  bool get hasLocation =>
      status == BilletterieLocationStatus.ok && location != null;
}

abstract final class BilletterieLocationService {
  static const nearbyRadiusMeters = 5000.0;

  static BilletterieUserLocation? _cached;
  static DateTime? _cachedAt;

  static BilletterieUserLocation? get cached => _cached;

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

  static Future<LocationPermission> requestOsPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  static Future<BilletterieLocationResult> requestAndGetPosition({
    bool forceRefresh = false,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (_cached != null) return BilletterieLocationResult.ok(_cached!);
        return BilletterieLocationResult.fail(
          BilletterieLocationStatus.serviceDisabled,
          'Activez le GPS / la localisation de votre téléphone, puis réessayez.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (_cached != null) return BilletterieLocationResult.ok(_cached!);
        return BilletterieLocationResult.fail(
          BilletterieLocationStatus.denied,
          'Autorisez l’accès à votre position pour vous situer sur la carte.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        if (_cached != null) return BilletterieLocationResult.ok(_cached!);
        return BilletterieLocationResult.fail(
          BilletterieLocationStatus.deniedForever,
          'La localisation est bloquée pour Mon Peya. Ouvrez les réglages et activez-la.',
        );
      }

      if (!forceRefresh && _cacheFresh) {
        return BilletterieLocationResult.ok(_cached!);
      }

      final position = await _resolvePosition(preferFresh: forceRefresh);
      if (position == null) {
        if (_cached != null) return BilletterieLocationResult.ok(_cached!);
        return BilletterieLocationResult.fail(
          BilletterieLocationStatus.error,
          'Impossible d’obtenir votre position pour le moment. Vérifiez que le GPS est activé et réessayez.',
        );
      }

      final loc = BilletterieUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _cached = loc;
      _cachedAt = DateTime.now();
      return BilletterieLocationResult.ok(loc);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Billetterie] location error: $e\n$st');
      }
      if (_cached != null) return BilletterieLocationResult.ok(_cached!);
      return BilletterieLocationResult.fail(
        BilletterieLocationStatus.error,
        'Impossible d’obtenir votre position pour le moment. Vérifiez que le GPS est activé et réessayez.',
      );
    }
  }

  static Future<Position?> _resolvePosition({required bool preferFresh}) async {
    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    if (!preferFresh && lastKnown != null) {
      unawaited(_refineInBackground());
      return lastKnown;
    }

    final fresh = await _fetchFreshPosition();
    if (fresh != null) return fresh;
    return lastKnown;
  }

  static Future<Position?> _fetchFreshPosition() async {
    try {
      return await Geolocator.getPositionStream(
        locationSettings: _settings(accuracy: LocationAccuracy.low),
      ).first.timeout(const Duration(seconds: 8));
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings(
          accuracy: LocationAccuracy.lowest,
          forceAndroidLocationManager: true,
        ),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {}

    return null;
  }

  static Future<void> _refineInBackground() async {
    try {
      final pos = await _fetchFreshPosition();
      if (pos == null) return;
      _cached = BilletterieUserLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _cachedAt = DateTime.now();
    } catch (_) {}
  }

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

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();
}
