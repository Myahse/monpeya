class LeadwayLifeBeneficiary {
  const LeadwayLifeBeneficiary({
    required this.firstName,
    required this.lastName,
    required this.relationship,
    required this.phone,
    required this.email,
    this.percentage = 0,
  });

  final String firstName;
  final String lastName;
  final String relationship;
  final num percentage;
  final String phone;
  final String email;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'relationship': relationship,
        'percentage': percentage,
        'phone': phone,
        'email': email,
      };
}

/// Corps POST /api/souscription
class LeadwayLifeSubscriptionRequest {
  const LeadwayLifeSubscriptionRequest({
    required this.telephone,
    required this.customerId,
    required this.productCode,
    required this.beneficiaries,
  });

  final String telephone;
  final String customerId;
  final String productCode;
  final List<LeadwayLifeBeneficiary> beneficiaries;

  Map<String, dynamic> toJson() => {
        'telephone': telephone,
        'customerId': customerId,
        'productCode': productCode,
        'beneficiaries': beneficiaries.map((e) => e.toJson()).toList(),
      };
}

class LeadwayLifeSubscriptionData {
  const LeadwayLifeSubscriptionData({
    required this.id,
    required this.subscriptionRef,
    required this.productCode,
    required this.policyNumber,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String subscriptionRef;
  final String productCode;
  final String policyNumber;
  final String status;
  final String? createdAt;

  factory LeadwayLifeSubscriptionData.fromJson(Map<String, dynamic> json) {
    return LeadwayLifeSubscriptionData(
      id: json['id']?.toString() ?? '',
      subscriptionRef: json['subscriptionRef']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      policyNumber: json['policyNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Réponse POST /api/souscription
class LeadwayLifeSubscriptionResult {
  const LeadwayLifeSubscriptionResult({
    required this.success,
    required this.data,
    this.raw,
  });

  final bool success;
  final LeadwayLifeSubscriptionData data;
  final Map<String, dynamic>? raw;

  factory LeadwayLifeSubscriptionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw FormatException('Réponse souscription Vie sans data: $json');
    }
    return LeadwayLifeSubscriptionResult(
      success: json['success'] == true,
      data: LeadwayLifeSubscriptionData.fromJson(Map<String, dynamic>.from(data)),
      raw: json,
    );
  }
}
