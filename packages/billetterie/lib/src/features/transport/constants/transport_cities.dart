import 'package:latlong2/latlong.dart';

/// Côte d'Ivoire cities / Abidjan communes for transport tickets.
abstract final class TransportCities {
  static const List<String> all = [
    'Abidjan',
    'Cocody',
    'Plateau',
    'Marcory',
    'Treichville',
    'Yopougon',
    'Abobo',
    'Adjamé',
    'Koumassi',
    'Port-Bouët',
    'Bingerville',
    'Anyama',
    'Songon',
    'Grand-Bassam',
    'Bouaké',
    'Yamoussoukro',
    'San-Pédro',
    'Korhogo',
    'Daloa',
    'Man',
    'Gagnoa',
    'Divo',
    'Abengourou',
    'Bondoukou',
    'Odienné',
    'Séguéla',
    'Ferkessédougou',
    'Soubré',
    'Issia',
    'Agboville',
  ];

  static const abidjan = LatLng(5.3364, -4.0267);

  /// Approximate centers for map markers / route polylines.
  static const Map<String, LatLng> coordinates = {
    'Abidjan': LatLng(5.3364, -4.0267),
    'Cocody': LatLng(5.3600, -3.9780),
    'Plateau': LatLng(5.3260, -4.0200),
    'Marcory': LatLng(5.2970, -3.9820),
    'Treichville': LatLng(5.3050, -4.0050),
    'Yopougon': LatLng(5.3360, -4.0850),
    'Abobo': LatLng(5.4160, -4.0200),
    'Adjamé': LatLng(5.3530, -4.0230),
    'Koumassi': LatLng(5.2900, -3.9550),
    'Port-Bouët': LatLng(5.2560, -3.9240),
    'Bingerville': LatLng(5.3550, -3.8850),
    'Anyama': LatLng(5.4940, -4.0510),
    'Songon': LatLng(5.3200, -4.2200),
    'Grand-Bassam': LatLng(5.2110, -3.7380),
    'Bouaké': LatLng(7.6900, -5.0300),
    'Yamoussoukro': LatLng(6.8270, -5.2890),
    'San-Pédro': LatLng(4.7480, -6.6360),
    'Korhogo': LatLng(9.4580, -5.6290),
    'Daloa': LatLng(6.8770, -6.4500),
    'Man': LatLng(7.4120, -7.5540),
    'Gagnoa': LatLng(6.1310, -5.9500),
    'Divo': LatLng(5.8370, -5.3570),
    'Abengourou': LatLng(6.7290, -3.4960),
    'Bondoukou': LatLng(8.0400, -2.8000),
    'Odienné': LatLng(9.5050, -7.5640),
    'Séguéla': LatLng(7.9610, -6.6730),
    'Ferkessédougou': LatLng(9.5930, -5.1940),
    'Soubré': LatLng(5.7860, -6.5930),
    'Issia': LatLng(6.4920, -6.5850),
    'Agboville': LatLng(5.9280, -4.2130),
  };

  /// Ticket / UI codes → canonical city name.
  static const Map<String, String> codeToCity = {
    'ABJ': 'Abidjan',
    'ABID': 'Abidjan',
    'CCDY': 'Cocody',
    'COC': 'Cocody',
    'PLTE': 'Plateau',
    'PLA': 'Plateau',
    'MRC': 'Marcory',
    'MAR': 'Marcory',
    'TRCH': 'Treichville',
    'TRE': 'Treichville',
    'YOP': 'Yopougon',
    'ABO': 'Abobo',
    'ADJ': 'Adjamé',
    'KOU': 'Koumassi',
    'POR': 'Port-Bouët',
    'PBT': 'Port-Bouët',
    'BIN': 'Bingerville',
    'ANY': 'Anyama',
    'SON': 'Songon',
    'GBA': 'Grand-Bassam',
    'GRA': 'Grand-Bassam',
    'BOU': 'Bouaké',
    'YAM': 'Yamoussoukro',
    'SAN': 'San-Pédro',
    'KOR': 'Korhogo',
    'DAL': 'Daloa',
    'MAN': 'Man',
    'GAG': 'Gagnoa',
    'DIV': 'Divo',
    'ABE': 'Abengourou',
    'BON': 'Bondoukou',
    'ODI': 'Odienné',
    'SEG': 'Séguéla',
    'FER': 'Ferkessédougou',
    'SOU': 'Soubré',
    'ISS': 'Issia',
    'AGB': 'Agboville',
  };

  /// Resolves a city name or ticket code to map coordinates.
  static LatLng? resolvePoint(String? raw) {
    final city = resolveCityName(raw);
    if (city == null) return null;
    return coordinates[city];
  }

  /// Canonical display name for a city label or code.
  static String? resolveCityName(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (lower == 'abj' || lower == 'abidjan') return 'Abidjan';

    for (final name in all) {
      if (name.toLowerCase() == lower) return name;
    }

    final code = trimmed.toUpperCase().replaceAll(RegExp(r'[^A-ZÀ-ÿ]'), '');
    final fromCode = codeToCity[code];
    if (fromCode != null) return fromCode;

    for (final entry in codeToCity.entries) {
      if (code.startsWith(entry.key) || entry.key.startsWith(code)) {
        return entry.value;
      }
    }

    for (final name in all) {
      if (lower.contains(name.toLowerCase()) ||
          name.toLowerCase().contains(lower)) {
        return name;
      }
    }
    return null;
  }
}
