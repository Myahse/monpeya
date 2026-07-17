/// Corps POST /api/souscription/{reference}/paiement
class LeadwayLifePaymentRequest {
  const LeadwayLifePaymentRequest({
    required this.method,
    required this.payerPhone,
    required this.returnUrl,
    required this.otp,
  });

  final String method;
  final String payerPhone;
  final String returnUrl;
  final String otp;

  Map<String, dynamic> toJson() => {
        'method': method,
        'payerPhone': payerPhone,
        'returnUrl': returnUrl,
        'otp': otp,
      };
}

class LeadwayLifePaymentData {
  const LeadwayLifePaymentData({
    required this.subscriptionRef,
    required this.transactionId,
    required this.redirectUrl,
    required this.paymentStatus,
  });

  final String subscriptionRef;
  final String transactionId;
  final String redirectUrl;
  final String paymentStatus;

  factory LeadwayLifePaymentData.fromJson(Map<String, dynamic> json) {
    return LeadwayLifePaymentData(
      subscriptionRef: json['subscriptionRef']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      redirectUrl: json['redirectUrl']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
    );
  }

  bool get isPaid {
    final s = paymentStatus.toUpperCase();
    return s == 'PAID' || s == 'SUCCESS' || s == 'COMPLETED' || s == 'SUCCESSFUL';
  }

  bool get isPending {
    final s = paymentStatus.toUpperCase();
    return s == 'PENDING' || s == 'INITIATED' || s == 'PROCESSING' || s.isEmpty;
  }
}

/// Réponse POST /api/souscription/{reference}/paiement
class LeadwayLifePaymentResult {
  const LeadwayLifePaymentResult({
    required this.success,
    required this.data,
    this.raw,
  });

  final bool success;
  final LeadwayLifePaymentData data;
  final Map<String, dynamic>? raw;

  factory LeadwayLifePaymentResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw FormatException('Réponse paiement Vie sans data: $json');
    }
    return LeadwayLifePaymentResult(
      success: json['success'] == true,
      data: LeadwayLifePaymentData.fromJson(Map<String, dynamic>.from(data)),
      raw: json,
    );
  }
}

/// Corps POST /api/souscription/check-paiement
class LeadwayLifePaymentCheckRequest {
  const LeadwayLifePaymentCheckRequest({required this.transactionId});

  final String transactionId;

  Map<String, dynamic> toJson() => {'transactionId': transactionId};
}

/// data de POST /api/souscription/check-paiement
class LeadwayLifePaymentCheckData {
  const LeadwayLifePaymentCheckData({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.payerRef,
    this.createdAt,
    this.updatedAt,
  });

  final String transactionId;
  final num amount;
  final String currency;
  final String status;
  final String payerRef;
  final String? createdAt;
  final String? updatedAt;

  factory LeadwayLifePaymentCheckData.fromJson(Map<String, dynamic> json) {
    return LeadwayLifePaymentCheckData(
      transactionId: json['transactionId']?.toString() ?? '',
      amount: json['amount'] is num ? json['amount'] as num : num.tryParse('${json['amount']}') ?? 0,
      currency: json['currency']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      payerRef: json['payerRef']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  bool get isPaid {
    final s = status.toUpperCase();
    return s == 'PAID' || s == 'SUCCESS' || s == 'COMPLETED' || s == 'SUCCESSFUL';
  }

  bool get isFailed {
    final s = status.toUpperCase();
    return s == 'FAILED' || s == 'CANCELLED' || s == 'CANCELED' || s == 'ERROR' || s == 'REJECTED';
  }
}

/// Réponse POST /api/souscription/check-paiement
class LeadwayLifePaymentCheckResult {
  const LeadwayLifePaymentCheckResult({
    required this.success,
    required this.data,
    this.raw,
  });

  final bool success;
  final LeadwayLifePaymentCheckData data;
  final Map<String, dynamic>? raw;

  factory LeadwayLifePaymentCheckResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw FormatException('Réponse check-paiement Vie sans data: $json');
    }
    return LeadwayLifePaymentCheckResult(
      success: json['success'] == true,
      data: LeadwayLifePaymentCheckData.fromJson(Map<String, dynamic>.from(data)),
      raw: json,
    );
  }
}
