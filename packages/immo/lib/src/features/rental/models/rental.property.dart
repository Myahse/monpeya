import 'package:immo/src/features/rental/utils/rental_image_helper.util.dart';

class RentalProperty {
  const RentalProperty({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.surface,
    required this.address,
    required this.city,
    required this.country,
    required this.statusLabel,
    required this.propertyType,
    required this.imageUrl,
    required this.imageUrls,
    required this.amenities,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.createdAt,
    this.ownerLogoUrl,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.rating = 0,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final double surface;
  final String address;
  final String city;
  final String country;
  final String? postalCode;
  final String statusLabel;
  final String propertyType;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<String> amenities;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String? ownerLogoUrl;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;
  final double rating;

  String get locationLabel {
    final parts = [city, country].where((p) => p.isNotEmpty);
    return parts.join(', ');
  }

  String get formattedPrice {
    if (price <= 0) return '—';
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        )} CFA';
  }

  String get listingStatus {
    final s = statusLabel.toLowerCase();
    if (s.contains('libre') || s.contains('actif')) return 'active';
    if (s.contains('attente')) return 'pending';
    return 'draft';
  }

  bool get isAvailableForRent {
    final s = statusLabel.toLowerCase();
    return s.contains('libre') ||
        s.contains('disponible') ||
        s.contains('actif') ||
        s.contains('available');
  }

  factory RentalProperty.fromBackend(
    Map<String, dynamic> item, {
    String? apiBaseUrl,
  }) {
    final typeBiens = item['typeBiens'] ?? item['typeBien'];
    final statuts = item['statuts'] ?? item['statut'];
    final utilisateurs = item['utilisateurs'] ?? item['proprietaire'];

    final imageUrl = resolvePropertyImageUrl(item, apiHostForLocalhost: apiBaseUrl);

    final rawImages = <String>[];
    final images = item['images'];
    if (images is List) {
      for (final img in images) {
        if (img is String && img.isNotEmpty) rawImages.add(img);
        if (img is Map && img['url'] is String) rawImages.add(img['url'] as String);
      }
    }
    if (rawImages.isEmpty && imageUrl != null) rawImages.add(imageUrl);

    final amenities = <String>[];
    final chars = item['caracteristiques'];
    if (chars is List) {
      for (final c in chars) {
        if (c is String) amenities.add(c);
        if (c is Map) {
          final name = c['nom'] ?? c['libelle'];
          if (name is String) amenities.add(name);
        }
      }
    }

    String ownerNom = '';
    String ownerPrenom = '';
    String ownerEmail = '';
    String ownerPhone = '';
    String? ownerLogoUrl;
    if (utilisateurs is Map) {
      ownerNom = (utilisateurs['nom'] as String?) ?? '';
      ownerPrenom = (utilisateurs['prenoms'] ?? utilisateurs['prenom'] as String?) ?? '';
      ownerEmail = (utilisateurs['email'] as String?) ?? '';
      ownerPhone = (utilisateurs['telephone'] as String?) ?? '';
      final logoRaw = utilisateurs['logo'] ??
          utilisateurs['photo'] ??
          utilisateurs['avatar'] ??
          utilisateurs['imageUrl'] ??
          utilisateurs['photoUrl'];
      if (logoRaw is String && logoRaw.trim().isNotEmpty) {
        var logo = logoRaw.trim();
        if (logo.contains('localhost') && apiBaseUrl != null) {
          final host = Uri.tryParse(apiBaseUrl)?.host;
          if (host != null && host.isNotEmpty) {
            logo = logo.replaceFirst('localhost', host);
          }
        }
        ownerLogoUrl = logo;
      }
    }

    DateTime? createdAt;
    final createdRaw = item['createdAt'] ?? item['dateCreation'];
    if (createdRaw is String) createdAt = DateTime.tryParse(createdRaw);

    return RentalProperty(
      id: (item['biensId'] ?? item['id'] ?? '').toString(),
      title: (item['nom'] ?? item['titre'] ?? 'Sans titre').toString(),
      description: (item['description'] as String?) ?? '',
      price: double.tryParse('${item['prix']}') ?? 0,
      surface: double.tryParse('${item['superficie']}') ?? 0,
      address: (item['adresse'] as String?) ?? '',
      city: (item['ville'] as String?) ?? '',
      country: _readCountry(item),
      postalCode: item['codePostal'] as String?,
      statusLabel: _readLabel(statuts),
      propertyType: _readType(typeBiens),
      imageUrl: imageUrl,
      imageUrls: rawImages,
      amenities: amenities,
      ownerName: '$ownerPrenom $ownerNom'.trim(),
      ownerPhone: ownerPhone,
      ownerEmail: ownerEmail,
      ownerLogoUrl: ownerLogoUrl,
      createdAt: createdAt,
      latitude: _toDouble(item['latitude']),
      longitude: _toDouble(item['longitude']),
      rating: double.tryParse('${item['evaluationQualite'] ?? item['rating']}') ?? 0,
    );
  }

  static String _readLabel(dynamic node) {
    if (node is Map) {
      return (node['libelle'] ?? node['code'] ?? node['nom'] ?? '—').toString();
    }
    return '—';
  }

  static String _readType(dynamic node) {
    if (node is Map) {
      return (node['libelle'] ?? node['nom'] ?? '—').toString();
    }
    return '—';
  }

  static String _readCountry(Map<String, dynamic> item) {
    final codePays = item['codePays'];
    if (codePays is Map) {
      return (codePays['nom'] ?? codePays['libelle'] ?? '').toString();
    }
    return (item['pays'] as String?) ?? '';
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse('$v');
  }
}
