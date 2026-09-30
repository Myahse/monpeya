import 'package:billetterie/src/shared/config/billetterie_env.registry.dart';

/// Raster basemap URLs for [flutter_map] (Carto fallback + Mapbox when configured).
abstract final class MapTilesConfig {
  static const _defineToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  static String? get _mapboxToken {
    final runtime = BilletterieEnvRegistry.mapboxAccessToken;
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return _defineToken.isEmpty ? null : _defineToken;
  }

  /// XYZ tile template for light or dark mode.
  static String tileUrl({required bool light}) {
    final token = _mapboxToken;
    if (token != null) {
      final style = light ? 'light-v11' : 'dark-v11';
      return 'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/256/{z}/{x}/{y}@2x'
          '?access_token=$token';
    }

    final cartoStyle = light ? 'light_all' : 'dark_all';
    return 'https://{s}.basemaps.cartocdn.com/$cartoStyle/{z}/{x}/{y}{r}.png';
  }
}
