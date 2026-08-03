import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a property location in Google Maps (app or browser).
Future<bool> openRentalLocationInGoogleMaps({
  double? latitude,
  double? longitude,
  String? placeLabel,
}) async {
  final lat = latitude;
  final lng = longitude;
  final label = (placeLabel ?? '').trim();

  final candidates = <Uri>[];

  if (lat != null && lng != null) {
    final q = label.isNotEmpty ? Uri.encodeComponent(label) : '$lat,$lng';
    candidates.addAll([
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      ),
      Uri.parse('comgooglemaps://?q=$lat,$lng'),
      Uri.parse('geo:$lat,$lng?q=$q'),
    ]);
  } else if (label.isNotEmpty) {
    final q = Uri.encodeComponent(label);
    candidates.addAll([
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      Uri.parse('comgooglemaps://?q=$q'),
      Uri.parse('geo:0,0?q=$q'),
    ]);
  } else {
    return false;
  }

  for (final uri in candidates) {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Immo] maps launch failed for $uri: $e');
      }
    }
  }
  return false;
}
