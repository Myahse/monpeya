class LeadwayApiPaymentRequest {
  const LeadwayApiPaymentRequest({
    required this.paymentId,
    required this.operator,
    required this.phoneNo,
    required this.otp,
    required this.token,
  });

  final String paymentId;
  final String operator;
  final String phoneNo;
  final String otp;
  final String token;

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'operator': operator,
        'phoneNo': phoneNo,
        'otp': otp,
        'token': token,
      };
}
