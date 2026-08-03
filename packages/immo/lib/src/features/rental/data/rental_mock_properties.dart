import 'package:immo/src/features/rental/models/rental.property.dart';

/// Demo listings for seeker browse when the Immo API returns nothing or fails.
abstract final class RentalMockProperties {
  static const _photos = [
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=800&q=80',
  ];

  static final List<RentalProperty> samples = [
    RentalProperty(
      id: 'MOCK-APT-COCODY',
      title: 'Appartement Cocody Angré',
      description: 'Bel appartement lumineux, 3 pièces, proche commerces.',
      price: 185000,
      surface: 95,
      address: 'Angré 8ème tranche',
      city: 'Cocody',
      country: 'Côte d’Ivoire',
      statusLabel: 'Libre',
      propertyType: 'Appartement',
      imageUrl: _photos[0],
      imageUrls: [_photos[0], _photos[1]],
      amenities: const ['Climatisation', 'Parking', 'Gardien'],
      ownerName: 'Kouassi Immobilier',
      ownerPhone: '+2250700000001',
      ownerEmail: 'contact@kouassi-immo.ci',
      createdAt: null,
      latitude: 5.3600,
      longitude: -3.9780,
      rating: 4.8,
    ),
    RentalProperty(
      id: 'MOCK-VILLA-RIVIERA',
      title: 'Villa Riviera Golf',
      description: 'Villa standing avec jardin et piscine.',
      price: 650000,
      surface: 280,
      address: 'Riviera Golf',
      city: 'Cocody',
      country: 'Côte d’Ivoire',
      statusLabel: 'Libre',
      propertyType: 'Villa',
      imageUrl: _photos[5],
      imageUrls: [_photos[5], _photos[4]],
      amenities: const ['Piscine', 'Jardin', 'Garage'],
      ownerName: 'Agence Riviera',
      ownerPhone: '+2250700000002',
      ownerEmail: 'agence@riviera.ci',
      createdAt: null,
      latitude: 5.3550,
      longitude: -3.9650,
      rating: 4.9,
    ),
    RentalProperty(
      id: 'MOCK-STUDIO-PLATEAU',
      title: 'Studio Plateau Centre',
      description: 'Studio meublé idéal professionnel, hyper centre.',
      price: 120000,
      surface: 42,
      address: 'Avenue Chardy',
      city: 'Plateau',
      country: 'Côte d’Ivoire',
      statusLabel: 'Libre',
      propertyType: 'Studio',
      imageUrl: _photos[2],
      imageUrls: [_photos[2]],
      amenities: const ['Meublé', 'Internet'],
      ownerName: 'Plateau Homes',
      ownerPhone: '+2250700000003',
      ownerEmail: 'hello@plateau-homes.ci',
      createdAt: null,
      latitude: 5.3260,
      longitude: -4.0200,
      rating: 4.6,
    ),
    RentalProperty(
      id: 'MOCK-APT-MARCORY',
      title: 'Appartement Marcory Zone 4',
      description: '2 chambres, salon spacieux, quartier animé.',
      price: 210000,
      surface: 110,
      address: 'Zone 4, Marcory',
      city: 'Marcory',
      country: 'Côte d’Ivoire',
      statusLabel: 'Libre',
      propertyType: 'Appartement',
      imageUrl: _photos[1],
      imageUrls: [_photos[1], _photos[3]],
      amenities: const ['Balcon', 'Ascenseur'],
      ownerName: 'Marcory Living',
      ownerPhone: '+2250700000004',
      ownerEmail: 'info@marcory-living.ci',
      createdAt: null,
      latitude: 5.2900,
      longitude: -3.9950,
      rating: 4.7,
    ),
    RentalProperty(
      id: 'MOCK-MAISON-YOP',
      title: 'Maison Yopougon Niangon',
      description: 'Maison familiale avec cour, calme et accessible.',
      price: 150000,
      surface: 130,
      address: 'Niangon Sud',
      city: 'Yopougon',
      country: 'Côte d’Ivoire',
      statusLabel: 'Libre',
      propertyType: 'Maison',
      imageUrl: _photos[4],
      imageUrls: [_photos[4]],
      amenities: const ['Cour', 'Forage'],
      ownerName: 'Yop Habitat',
      ownerPhone: '+2250700000005',
      ownerEmail: 'contact@yop-habitat.ci',
      createdAt: null,
      latitude: 5.3380,
      longitude: -4.0780,
      rating: 4.5,
    ),
    RentalProperty(
      id: 'MOCK-APT-ABIDJAN',
      title: 'Appartement Novotel City',
      description: 'Vue dégagée, sécurité 24h, proche routes principales.',
      price: 245000,
      surface: 88,
      address: 'Boulevard VGE',
      city: 'Abidjan',
      country: 'Côte d’Ivoire',
      statusLabel: 'Libre',
      propertyType: 'Appartement',
      imageUrl: _photos[3],
      imageUrls: [_photos[3], _photos[0]],
      amenities: const ['Gardien', 'Parking', 'Ascenseur'],
      ownerName: 'City Rent CI',
      ownerPhone: '+2250700000006',
      ownerEmail: 'rent@cityrent.ci',
      createdAt: null,
      latitude: 5.3197,
      longitude: -4.0267,
      rating: 4.8,
    ),
  ];

  static RentalProperty? byId(String id) {
    for (final property in samples) {
      if (property.id == id) return property;
    }
    return null;
  }

  /// Assigns stock photos to API listings that arrived without images.
  static List<RentalProperty> enrichMissingImages(List<RentalProperty> items) {
    if (items.isEmpty) return items;

    return [
      for (var i = 0; i < items.length; i++)
        _withFallbackPhoto(items[i], i),
    ];
  }

  static RentalProperty _withFallbackPhoto(RentalProperty property, int index) {
    final hasPhoto = property.imageUrl?.trim().isNotEmpty == true ||
        property.imageUrls.any((u) => u.trim().isNotEmpty);
    if (hasPhoto) return property;

    final photo = _photos[index % _photos.length];
    return RentalProperty(
      id: property.id,
      title: property.title,
      description: property.description,
      price: property.price,
      surface: property.surface,
      address: property.address,
      city: property.city,
      country: property.country,
      postalCode: property.postalCode,
      statusLabel: property.statusLabel,
      propertyType: property.propertyType,
      imageUrl: photo,
      imageUrls: [photo],
      amenities: property.amenities,
      ownerName: property.ownerName,
      ownerPhone: property.ownerPhone,
      ownerEmail: property.ownerEmail,
      ownerLogoUrl: property.ownerLogoUrl,
      createdAt: property.createdAt,
      latitude: property.latitude,
      longitude: property.longitude,
      rating: property.rating,
    );
  }
}
