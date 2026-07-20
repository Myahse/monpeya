class PeyapayGsmClientProfile {
  const PeyapayGsmClientProfile({
    this.codeClient,
    this.gsmPrincipale,
    this.nomClient,
    this.changerTelephone = false,
  });

  final String? codeClient;
  final String? gsmPrincipale;
  final String? nomClient;
  final bool changerTelephone;

  factory PeyapayGsmClientProfile.fromJson(Map<String, dynamic> json) {
    var nomClient = json['nomClient']?.toString();
    final accounts = json['datasCompte'];
    if ((nomClient == null || nomClient.isEmpty) && accounts is List && accounts.isNotEmpty) {
      final firstAccount = accounts.first;
      if (firstAccount is Map) {
        final wclients = firstAccount['wclients'];
        if (wclients is Map) {
          nomClient = wclients['nomClient']?.toString();
        }
      }
    }

    return PeyapayGsmClientProfile(
      codeClient: json['codeClient']?.toString(),
      gsmPrincipale: json['gsmPrincipale']?.toString(),
      nomClient: nomClient,
      changerTelephone: json['changerTelephone'] == true,
    );
  }
}

class PeyapayGsmSearchResult {
  const PeyapayGsmSearchResult({
    required this.count,
    this.items = const [],
  });

  final int count;
  final List<PeyapayGsmClientProfile> items;

  bool get isRecognized => items.isNotEmpty;

  PeyapayGsmClientProfile? get firstProfile => items.isEmpty ? null : items.first;
}

class PeyapayPinVerificationResult {
  const PeyapayPinVerificationResult({
    this.gsmPrincipale,
    this.codePaysResidence,
    this.solde,
  });

  final String? gsmPrincipale;
  final String? codePaysResidence;
  final String? solde;

  factory PeyapayPinVerificationResult.fromJson(Map<String, dynamic> json) {
    return PeyapayPinVerificationResult(
      gsmPrincipale: json['gsmPrincipale']?.toString(),
      codePaysResidence: json['codePaysResidence']?.toString(),
      solde: json['solde']?.toString(),
    );
  }
}
