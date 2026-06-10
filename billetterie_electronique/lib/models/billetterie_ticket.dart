import 'dart:convert';

class BilletterieTicketType {
  const BilletterieTicketType({
    required this.id,
    required this.name,
    required this.scope,
    required this.createdAt,
    this.description,
    this.price,
    this.currency,
  });

  final String id;
  final String name;
  final String scope;
  final String createdAt;
  final String? description;
  final double? price;
  final String? currency;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scope': scope,
        'createdAt': createdAt,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (currency != null) 'currency': currency,
      };

  factory BilletterieTicketType.fromJson(Map<String, dynamic> json) {
    return BilletterieTicketType(
      id: json['id'] as String,
      name: json['name'] as String,
      scope: json['scope'] == 'event' ? 'event' : 'other',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

class BilletterieTicket {
  const BilletterieTicket({
    required this.id,
    required this.typeId,
    required this.typeName,
    required this.holderName,
    required this.createdAt,
    required this.qrPayload,
    this.holderPhone,
    this.note,
    this.amount,
    this.currency,
  });

  final String id;
  final String typeId;
  final String typeName;
  final String holderName;
  final String createdAt;
  final String qrPayload;
  final String? holderPhone;
  final String? note;
  final double? amount;
  final String? currency;

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeId': typeId,
        'typeName': typeName,
        'holderName': holderName,
        'createdAt': createdAt,
        'qrPayload': qrPayload,
        if (holderPhone != null) 'holderPhone': holderPhone,
        if (note != null) 'note': note,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
      };

  factory BilletterieTicket.fromJson(Map<String, dynamic> json) {
    return BilletterieTicket(
      id: json['id'] as String,
      typeId: json['typeId'] as String,
      typeName: json['typeName'] as String,
      holderName: json['holderName'] as String,
      createdAt: json['createdAt'] as String,
      qrPayload: json['qrPayload'] as String,
      holderPhone: json['holderPhone'] as String?,
      note: json['note'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

String buildTicketQrPayload({
  required String ticketId,
  required String typeId,
  required String typeName,
  required String holderName,
  required String createdAt,
  String? holderPhone,
  String? note,
  double? amount,
  String? currency,
}) {
  return jsonEncode({
    'v': 1,
    'domain': 'nteri-billetterie',
    'ticketId': ticketId,
    'typeId': typeId,
    'typeName': typeName,
    'holderName': holderName,
    'createdAt': createdAt,
    if (holderPhone != null) 'holderPhone': holderPhone,
    if (note != null) 'note': note,
    if (amount != null) 'amount': amount,
    if (currency != null) 'currency': currency,
  });
}
