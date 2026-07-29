class LeadwayQuoteResponse {
  const LeadwayQuoteResponse({
    required this.quoteNo,
    required this.id,
    required this.quoteAmount,
    required this.raw,
  });

  final String quoteNo;
  final String id;
  final int quoteAmount;
  final Map<String, dynamic> raw;

  factory LeadwayQuoteResponse.fromJson(Map<String, dynamic> json) {
    return LeadwayQuoteResponse(
      quoteNo: (json['quoteNo'] ?? json['quote_no'] ?? '') as String,
      id: (json['id'] ?? '') as String,
      quoteAmount: (json['quoteAmount'] ?? json['quote_amount'] ?? 0) as int,
      raw: json,
    );
  }
}
