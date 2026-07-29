class LeadwayApiPaymentCheckRequest {
  const LeadwayApiPaymentCheckRequest({
    required this.paymentId,
  });

  final String paymentId;

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
      };
}
