/// Corps de la requête POST /api/auto/paiement (étape 1 — initier le paiement).
class LeadwayApiPaymentInitRequest {
  const LeadwayApiPaymentInitRequest({
    required this.quoteNo,
    required this.amount,
    required this.operator,
    required this.phoneNo,
    required this.email,
    required this.effectDate,
    required this.agentCode,
    required this.deliveryLocation,
  });

  final String quoteNo;
  final int amount;
  final String operator;
  final String phoneNo;
  final String email;
  final String effectDate;
  final String agentCode;
  final String deliveryLocation;

  Map<String, dynamic> toJson() => {
        'quoteNo': quoteNo,
        'amount': amount,
        'operator': operator,
        'phoneNo': phoneNo,
        'email': email,
        'effectDate': effectDate,
        'agentCode': agentCode,
        'deliveryLocation': deliveryLocation,
      };
}
