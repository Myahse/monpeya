import 'dart:convert';

class CreateListingDraft {
  CreateListingDraft();

  String propertyType = 'house';
  String address = '';
  String city = '';
  String postalCode = '';
  double? latitude;
  double? longitude;
  String superficie = '';
  final List<String> amenities = [];
  final List<String> photoPaths = [];
  String title = '';
  String description = '';
  String price = '';
  bool displayExactLocation = true;

  String get typeBiensId => propertyType == 'building'
      ? '004648d3-63ab-4405-b258-aa26e382d392'
      : '0957a631-c7db-49e8-9517-22aea67a849e';

  Map<String, dynamic> toCreatePayload({
    String? utilisateursId,
    List<String> photoUrls = const [],
    String? codePaysId,
  }) {
    final photoField = photoUrls.length > 1
        ? jsonEncode(photoUrls)
        : (photoUrls.isNotEmpty ? photoUrls.first : '');

    return {
      'nom': title,
      'description': description,
      'prix': double.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      'superficie': double.tryParse(superficie) ?? 0,
      'adresse': address,
      'ville': city,
      'codePostal': postalCode,
      'typeBiensId': typeBiensId,
      'dateAcquisition': DateTime.now().toIso8601String().split('T').first,
      'statut': 'libre',
      'commodities': jsonEncode(amenities),
      'photo': photoField,
      if (codePaysId != null && codePaysId.isNotEmpty) 'codePaysId': codePaysId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (utilisateursId != null && utilisateursId.isNotEmpty)
        'utilisateursId': utilisateursId,
    };
  }
}
