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
  });

  final int id;
  final String name;
  final String unit;
  final double price;
  final String currency;
  final String? market;
  final String? updatedBy;
  final DateTime? updatedAt;

  String get priceLabel =>
      '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} $currency';

  factory GrenierProduit.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final raw = json['updatedAt']?.toString();
    if (raw != null && raw.isNotEmpty) {
      updatedAt = DateTime.tryParse(raw);
    }
    return GrenierProduit(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'XOF',
      market: json['market']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      updatedAt: updatedAt,
    );
  }

  GrenierProduit copyWith({double? price, DateTime? updatedAt}) {
    return GrenierProduit(
      id: id,
      name: name,
      unit: unit,
      price: price ?? this.price,
      currency: currency,
      market: market,
      updatedBy: updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
