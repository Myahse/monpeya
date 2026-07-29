class PeyapayClientTransferResult {
  const PeyapayClientTransferResult({
    this.numeroOperation,
    this.trId,
    this.raw,
  });

  final String? numeroOperation;
  final String? trId;
  final Map<String, dynamic>? raw;

  factory PeyapayClientTransferResult.fromJson(Map<String, dynamic> json) {
    return PeyapayClientTransferResult(
      numeroOperation: json['numeroOperation']?.toString() ?? json['numOperation']?.toString(),
      trId: json['trId']?.toString(),
      raw: json,
    );
  }
}

/// PeyaPay wallet contact resolved via `/wClients/rechercheGsm`.
class PeyapayTransferContact {
  const PeyapayTransferContact({
    required this.name,
    required this.phoneDigits,
    this.codeClient,
    this.displayPhone,
  });

  final String name;
  final String phoneDigits;
  final String? codeClient;
  final String? displayPhone;

  String get phoneLabel => displayPhone ?? phoneDigits;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneDigits': phoneDigits,
        if (codeClient != null) 'codeClient': codeClient,
        if (displayPhone != null) 'displayPhone': displayPhone,
      };

  factory PeyapayTransferContact.fromJson(Map<String, dynamic> json) {
    return PeyapayTransferContact(
      name: json['name']?.toString() ?? '',
      phoneDigits: json['phoneDigits']?.toString() ?? '',
      codeClient: json['codeClient']?.toString(),
      displayPhone: json['displayPhone']?.toString(),
    );
  }
}
