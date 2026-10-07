/// One price reading of a product.
class GrenierPricePoint {
  const GrenierPricePoint({required this.at, required this.price});

  final DateTime at;
  final double price;

  static GrenierPricePoint? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(
      (raw['at'] ?? raw['date'] ?? raw['updatedAt'])?.toString() ?? '',
    );
    final price = (raw['price'] ?? raw['prix']) as num?;
    if (at == null || price == null) return null;
    return GrenierPricePoint(at: at, price: price.toDouble());
  }
}

class GrenierProduit {
  const GrenierProduit({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.currency,
    this.market,
    this.updatedBy,
    this.updatedAt,
    this.imageUrl,
    this.history = const [],
  });

  final int id;
  final String name;
  final String unit;
  final double price;
  final String currency;
  final String? market;
  final String? updatedBy;
  final DateTime? updatedAt;

  /// Product photo, when the Mon Grenier API provides one.
  final String? imageUrl;

  /// Past prices, oldest first, when the API provides them.
  final List<GrenierPricePoint> history;

  String get priceLabel => '${formatAmount(price)} $currency';

  /// `1250000` → `1 250 000`.
  static String formatAmount(num value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );

  factory GrenierProduit.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final raw = json['updatedAt']?.toString();
    if (raw != null && raw.isNotEmpty) {
      updatedAt = DateTime.tryParse(raw);
    }
    final image = (json['imageUrl'] ?? json['image'] ?? json['photo'])
        ?.toString()
        .trim();
    final rawHistory = json['history'] ?? json['historique'];
    final history = rawHistory is List
        ? (rawHistory
            .map(GrenierPricePoint.tryParse)
            .whereType<GrenierPricePoint>()
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at)))
        : const <GrenierPricePoint>[];
    return GrenierProduit(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'XOF',
      market: json['market']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      updatedAt: updatedAt,
      imageUrl: image == null || image.isEmpty ? null : image,
      history: history,
    );
  }

  GrenierProduit copyWith({
    double? price,
    DateTime? updatedAt,
    List<GrenierPricePoint>? history,
  }) {
    return GrenierProduit(
      id: id,
      name: name,
      unit: unit,
      price: price ?? this.price,
      currency: currency,
      market: market,
      updatedBy: updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl,
      history: history ?? this.history,
    );
  }
}
