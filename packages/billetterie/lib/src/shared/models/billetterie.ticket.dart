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
    this.eventCode,
    this.purpose,
    this.status,
    this.orderRef,
  });

  /// Public ticket code (`ticketCode`).
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
  final String? eventCode;
  final String? purpose;
  final String? status;
  final String? orderRef;

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
        if (eventCode != null) 'eventCode': eventCode,
        if (purpose != null) 'purpose': purpose,
        if (status != null) 'status': status,
        if (orderRef != null) 'orderRef': orderRef,
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
      eventCode: json['eventCode'] as String?,
      purpose: json['purpose'] as String?,
      status: json['status'] as String?,
      orderRef: json['orderRef'] as String?,
    );
  }

  factory BilletterieTicket.fromTicketingJson(Map<String, dynamic> json) {
    final ticketCode = json['ticketCode']?.toString() ?? '';
    final eventCode = json['eventCode']?.toString();
    final purpose = json['purpose']?.toString() ?? 'EVENT';
    final purchasedAt = json['purchasedAt']?.toString();
    final generatedAt = json['generatedAt']?.toString();
    final amountPaid = (json['amountPaid'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble();

    return BilletterieTicket(
      id: ticketCode,
      typeId: eventCode ?? purpose,
      typeName: json['title']?.toString() ?? ticketCode,
      holderName: json['buyerName']?.toString() ?? 'Titulaire',
      holderPhone: json['buyerPhone']?.toString(),
      createdAt: purchasedAt ?? generatedAt ?? DateTime.now().toIso8601String(),
      qrPayload: json['qrPayload']?.toString() ?? '',
      amount: amountPaid,
      currency: 'XOF',
      eventCode: eventCode,
      purpose: purpose,
      status: json['status']?.toString(),
      orderRef: json['orderRef']?.toString(),
    );
  }

  BilletterieTicket copyWith({String? qrPayload}) {
    return BilletterieTicket(
      id: id,
      typeId: typeId,
      typeName: typeName,
      holderName: holderName,
      createdAt: createdAt,
      qrPayload: qrPayload ?? this.qrPayload,
      holderPhone: holderPhone,
      note: note,
      amount: amount,
      currency: currency,
      eventCode: eventCode,
      purpose: purpose,
      status: status,
      orderRef: orderRef,
    );
  }
}

String makeTicketId(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}';
