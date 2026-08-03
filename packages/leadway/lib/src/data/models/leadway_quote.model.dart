class LeadwayQuote {
  const LeadwayQuote({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.value,
    required this.cylinder,
    required this.premium,
    required this.createdAt,
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final int value;
  final String cylinder;
  final int premium;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'value': value,
        'cylinder': cylinder,
        'premium': premium,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LeadwayQuote.fromJson(Map<String, dynamic> json) => LeadwayQuote(
        id: json['id'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        value: json['value'] as int,
        cylinder: json['cylinder'] as String,
        premium: json['premium'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
