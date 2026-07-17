class LeadwayLifeMoneyAmount {
  const LeadwayLifeMoneyAmount({
    required this.amount,
    required this.currency,
  });

  final num amount;
  final String currency;

  factory LeadwayLifeMoneyAmount.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LeadwayLifeMoneyAmount(amount: 0, currency: 'XOF');
    }
    return LeadwayLifeMoneyAmount(
      amount: json['amount'] is num ? json['amount'] as num : num.tryParse('${json['amount']}') ?? 0,
      currency: json['currency']?.toString() ?? 'XOF',
    );
  }

  int get amountRounded => amount.round();
}

class LeadwayLifePremium {
  const LeadwayLifePremium({
    required this.gross,
    required this.net,
    required this.tax,
    required this.frequency,
    required this.breakdown,
  });

  final LeadwayLifeMoneyAmount gross;
  final LeadwayLifeMoneyAmount net;
  final LeadwayLifeMoneyAmount tax;
  final String frequency;
  final List<String> breakdown;

  factory LeadwayLifePremium.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LeadwayLifePremium(
        gross: LeadwayLifeMoneyAmount(amount: 0, currency: 'XOF'),
        net: LeadwayLifeMoneyAmount(amount: 0, currency: 'XOF'),
        tax: LeadwayLifeMoneyAmount(amount: 0, currency: 'XOF'),
        frequency: '',
        breakdown: [],
      );
    }
    final breakdownRaw = json['breakdown'];
    return LeadwayLifePremium(
      gross: LeadwayLifeMoneyAmount.fromJson(
        json['gross'] is Map ? Map<String, dynamic>.from(json['gross'] as Map) : null,
      ),
      net: LeadwayLifeMoneyAmount.fromJson(
        json['net'] is Map ? Map<String, dynamic>.from(json['net'] as Map) : null,
      ),
      tax: LeadwayLifeMoneyAmount.fromJson(
        json['tax'] is Map ? Map<String, dynamic>.from(json['tax'] as Map) : null,
      ),
      frequency: json['frequency']?.toString() ?? '',
      breakdown: breakdownRaw is List
          ? breakdownRaw.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

/// Contenu de data dans la réponse cotation Vie.
class LeadwayLifeCotationData {
  const LeadwayLifeCotationData({
    required this.subscriptionRef,
    required this.productCode,
    required this.status,
    required this.premium,
    required this.computedAt,
  });

  final String subscriptionRef;
  final String productCode;
  final String status;
  final LeadwayLifePremium premium;
  final String? computedAt;

  factory LeadwayLifeCotationData.fromJson(Map<String, dynamic> json) {
    return LeadwayLifeCotationData(
      subscriptionRef: json['subscriptionRef']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      premium: LeadwayLifePremium.fromJson(
        json['premium'] is Map ? Map<String, dynamic>.from(json['premium'] as Map) : null,
      ),
      computedAt: json['computedAt']?.toString(),
    );
  }
}

/// Réponse POST /api/souscription/cotation
class LeadwayLifeCotationResult {
  const LeadwayLifeCotationResult({
    required this.success,
    required this.data,
    this.raw,
  });

  final bool success;
  final LeadwayLifeCotationData data;
  final Map<String, dynamic>? raw;

  factory LeadwayLifeCotationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw FormatException('Réponse cotation Vie sans data: $json');
    }
    return LeadwayLifeCotationResult(
      success: json['success'] == true,
      data: LeadwayLifeCotationData.fromJson(Map<String, dynamic>.from(data)),
      raw: json,
    );
  }
}
