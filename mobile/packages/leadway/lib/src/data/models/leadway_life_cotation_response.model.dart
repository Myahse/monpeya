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

  LeadwayLifePremium copyWith({
    LeadwayLifeMoneyAmount? gross,
    LeadwayLifeMoneyAmount? net,
    LeadwayLifeMoneyAmount? tax,
    String? frequency,
    List<String>? breakdown,
  }) {
    return LeadwayLifePremium(
      gross: gross ?? this.gross,
      net: net ?? this.net,
      tax: tax ?? this.tax,
      frequency: frequency ?? this.frequency,
      breakdown: breakdown ?? this.breakdown,
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

  LeadwayLifeCotationData copyWith({
    String? subscriptionRef,
    String? productCode,
    String? status,
    LeadwayLifePremium? premium,
    String? computedAt,
  }) {
    return LeadwayLifeCotationData(
      subscriptionRef: subscriptionRef ?? this.subscriptionRef,
      productCode: productCode ?? this.productCode,
      status: status ?? this.status,
      premium: premium ?? this.premium,
      computedAt: computedAt ?? this.computedAt,
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

  /// Si l'API renvoie `data.premium.gross.amount == 0`, utilise [tierInputAmount]
  /// (montant saisi dans la requête) pour permettre de continuer le parcours.
  LeadwayLifeCotationResult withTierInputAmountFallback(int tierInputAmount) {
    if (tierInputAmount <= 0 || data.premium.gross.amount != 0) {
      return this;
    }

    final currency = data.premium.gross.currency.isNotEmpty
        ? data.premium.gross.currency
        : 'XOF';
    final gross = LeadwayLifeMoneyAmount(amount: tierInputAmount, currency: currency);

    return LeadwayLifeCotationResult(
      success: success,
      data: data.copyWith(
        premium: data.premium.copyWith(gross: gross),
      ),
      raw: raw,
    );
  }
}
