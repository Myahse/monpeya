import 'package:leadway/src/data/models/leadway_life_cotation_response.model.dart';

/// Item d'une souscription dans GET /api/souscription
class LeadwayLifeSubscriptionItem {
  const LeadwayLifeSubscriptionItem({
    required this.id,
    required this.subscriptionRef,
    required this.customerId,
    required this.productCode,
    required this.policyNumber,
    required this.premium,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String subscriptionRef;
  final String customerId;
  final String productCode;
  final String policyNumber;
  final LeadwayLifePremium premium;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  factory LeadwayLifeSubscriptionItem.fromJson(Map<String, dynamic> json) {
    return LeadwayLifeSubscriptionItem(
      id: json['id']?.toString() ?? '',
      subscriptionRef: json['subscriptionRef']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      policyNumber: json['policyNumber']?.toString() ?? '',
      premium: LeadwayLifePremium.fromJson(
        json['premium'] is Map ? Map<String, dynamic>.from(json['premium'] as Map) : null,
      ),
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

/// Page paginée générique Vie.
class LeadwayLifePagedResult<T> {
  const LeadwayLifePagedResult({
    required this.items,
    required this.totalItems,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int totalItems;
  final int page;
  final int pageSize;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;

  factory LeadwayLifePagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = json['items'];
    return LeadwayLifePagedResult<T>(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => itemFromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      totalItems: _asInt(json['totalItems']),
      page: _asInt(json['page']),
      pageSize: _asInt(json['pageSize']),
      totalPages: _asInt(json['totalPages']),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

/// Réponse GET /api/souscription (liste)
class LeadwayLifeSubscriptionListResult {
  const LeadwayLifeSubscriptionListResult({
    required this.success,
    required this.subscriptions,
    this.raw,
  });

  final bool success;
  final LeadwayLifePagedResult<LeadwayLifeSubscriptionItem> subscriptions;
  final Map<String, dynamic>? raw;

  factory LeadwayLifeSubscriptionListResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw FormatException('Réponse liste souscriptions sans data: $json');
    }
    final dataMap = Map<String, dynamic>.from(data);
    final subs = dataMap['subscriptions'];
    if (subs is! Map) {
      throw FormatException('Réponse liste souscriptions sans subscriptions: $json');
    }
    return LeadwayLifeSubscriptionListResult(
      success: json['success'] == true,
      subscriptions: LeadwayLifePagedResult.fromJson(
        Map<String, dynamic>.from(subs),
        LeadwayLifeSubscriptionItem.fromJson,
      ),
      raw: json,
    );
  }
}

/// Disponibilité police — GET /api/souscription/{reference}/issue
class LeadwayLifeIssueData {
  const LeadwayLifeIssueData({
    required this.subscriptionRef,
    required this.message,
    required this.policyStatus,
    required this.status,
  });

  final String subscriptionRef;
  final String message;
  final String policyStatus;
  final String status;

  factory LeadwayLifeIssueData.fromJson(Map<String, dynamic> json) {
    return LeadwayLifeIssueData(
      subscriptionRef: json['subscriptionRef']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      policyStatus: json['policyStatus']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  bool get isAvailable {
    final s = '${policyStatus}_$status'.toUpperCase();
    return s.contains('AVAILABLE') ||
        s.contains('ISSUED') ||
        s.contains('READY') ||
        s.contains('ACTIVE') ||
        s.contains('SUCCESS');
  }
}

class LeadwayLifeIssueResult {
  const LeadwayLifeIssueResult({
    required this.success,
    required this.data,
    this.raw,
  });

  final bool success;
  final LeadwayLifeIssueData data;
  final Map<String, dynamic>? raw;

  factory LeadwayLifeIssueResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw FormatException('Réponse issue police sans data: $json');
    }
    return LeadwayLifeIssueResult(
      success: json['success'] == true,
      data: LeadwayLifeIssueData.fromJson(Map<String, dynamic>.from(data)),
      raw: json,
    );
  }
}

/// Item paiement récurrent — GET /api/souscription/paiement-recurrent
class LeadwayLifeRecurringPaymentItem {
  const LeadwayLifeRecurringPaymentItem({
    required this.id,
    required this.customerId,
    required this.productCode,
    required this.policyNumber,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.frequency,
    required this.status,
    this.nextPaymentDate,
    this.lastPaymentDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerId;
  final String productCode;
  final String policyNumber;
  final num amount;
  final String currency;
  final String paymentMethod;
  final String frequency;
  final String status;
  final String? nextPaymentDate;
  final String? lastPaymentDate;
  final String? createdAt;
  final String? updatedAt;

  factory LeadwayLifeRecurringPaymentItem.fromJson(Map<String, dynamic> json) {
    return LeadwayLifeRecurringPaymentItem(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      policyNumber: json['policyNumber']?.toString() ?? '',
      amount: json['amount'] is num ? json['amount'] as num : num.tryParse('${json['amount']}') ?? 0,
      currency: json['currency']?.toString() ?? 'XOF',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      nextPaymentDate: json['nextPaymentDate']?.toString(),
      lastPaymentDate: json['lastPaymentDate']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

/// Réponse GET /api/souscription/paiement-recurrent
class LeadwayLifeRecurringPaymentListResult {
  const LeadwayLifeRecurringPaymentListResult({
    required this.success,
    required this.page,
    this.raw,
  });

  final bool success;
  final LeadwayLifePagedResult<LeadwayLifeRecurringPaymentItem> page;
  final Map<String, dynamic>? raw;

  factory LeadwayLifeRecurringPaymentListResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw FormatException('Réponse paiements récurrents sans data: $json');
    }
    return LeadwayLifeRecurringPaymentListResult(
      success: json['success'] == true,
      page: LeadwayLifePagedResult.fromJson(
        Map<String, dynamic>.from(data),
        LeadwayLifeRecurringPaymentItem.fromJson,
      ),
      raw: json,
    );
  }
}
