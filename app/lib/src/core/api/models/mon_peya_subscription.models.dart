import 'package:flutter/foundation.dart';

/// Subscription plan from Mon Peya backend (`/v1/plans`).
@immutable
class MonPeyaPlan {
  const MonPeyaPlan({
    required this.code,
    required this.name,
    this.description,
    this.price = 0,
    this.currency = 'XOF',
    this.billingPeriod = 'MONTHLY',
    this.trialDays = 0,
    this.isDefault = false,
    this.planKind = 'SINGLE',
    this.moduleCodes = const [],
  });

  final String code;
  final String name;
  final String? description;
  final num price;
  final String currency;
  final String billingPeriod;
  final int trialDays;
  final bool isDefault;
  /// SINGLE | GROUPED
  final String planKind;
  final List<String> moduleCodes;

  bool get isGrouped => planKind.toUpperCase() == 'GROUPED';
  bool get isSingle => !isGrouped;

  factory MonPeyaPlan.fromJson(Map<String, dynamic> json) {
    final modules = <String>[];
    final raw = json['moduleCodes'];
    if (raw is List) {
      for (final e in raw) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) modules.add(s);
      }
    }
    return MonPeyaPlan(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: json['price'] is num
          ? json['price'] as num
          : num.tryParse('${json['price']}') ?? 0,
      currency: json['currency']?.toString() ?? 'XOF',
      billingPeriod: json['billingPeriod']?.toString() ?? 'MONTHLY',
      trialDays: json['trialDays'] is int
          ? json['trialDays'] as int
          : int.tryParse('${json['trialDays']}') ?? 0,
      isDefault: json['isDefault'] == true,
      planKind: (json['planKind']?.toString() ?? 'SINGLE').toUpperCase(),
      moduleCodes: modules,
    );
  }
}

/// Active subscription from `/v1/subscriptions/me` or `/subscribe`.
@immutable
class MonPeyaSubscription {
  const MonPeyaSubscription({
    this.subscriptionId,
    this.moduleCode,
    this.role,
    this.planCode,
    this.planName,
    this.status,
    this.startAt,
    this.endAt,
    this.isMockPayment,
  });

  final int? subscriptionId;
  final String? moduleCode;
  final String? role;
  final String? planCode;
  final String? planName;
  final String? status;
  final String? startAt;
  final String? endAt;
  final bool? isMockPayment;

  bool get isActive =>
      status == 'ACTIVE' || status == 'TRIAL';

  factory MonPeyaSubscription.fromJson(Map<String, dynamic> json) {
    return MonPeyaSubscription(
      subscriptionId: json['subscriptionId'] is int
          ? json['subscriptionId'] as int
          : int.tryParse('${json['subscriptionId']}'),
      moduleCode: json['moduleCode']?.toString(),
      role: json['role']?.toString(),
      planCode: json['planCode']?.toString(),
      planName: json['planName']?.toString(),
      status: json['status']?.toString(),
      startAt: json['startAt']?.toString(),
      endAt: json['endAt']?.toString(),
      isMockPayment: json['isMockPayment'] as bool?,
    );
  }
}

/// Request from `/v1/subscriptions/requests/*` .
@immutable
class MonPeyaSubscriptionRequest {
  const MonPeyaSubscriptionRequest({
    this.requestId,
    this.requestType,
    this.moduleCode,
    this.role,
    this.planCode,
    this.planName,
    this.amount,
    this.currency,
    this.status,
    this.paymentStatus,
    this.paymentRef,
    this.reviewNote,
    this.createdAt,
  });

  final int? requestId;
  final String? requestType;
  final String? moduleCode;
  final String? role;
  final String? planCode;
  final String? planName;
  final num? amount;
  final String? currency;
  final String? status;
  final String? paymentStatus;
  final String? paymentRef;
  final String? reviewNote;
  final String? createdAt;

  bool get isOpen =>
      status == 'WAITING_FOR_APPROVAL' || status == 'ON_REVIEW';

  bool get isDeplafonnement => requestType == 'DEPLAFONNEMENT';

  factory MonPeyaSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return MonPeyaSubscriptionRequest(
      requestId: json['requestId'] is int
          ? json['requestId'] as int
          : int.tryParse('${json['requestId']}'),
      requestType: json['requestType']?.toString(),
      moduleCode: json['moduleCode']?.toString(),
      role: json['role']?.toString(),
      planCode: json['planCode']?.toString(),
      planName: json['planName']?.toString(),
      amount: json['amount'] is num
          ? json['amount'] as num
          : num.tryParse('${json['amount']}'),
      currency: json['currency']?.toString(),
      status: json['status']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      paymentRef: json['paymentRef']?.toString(),
      reviewNote: json['reviewNote']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
