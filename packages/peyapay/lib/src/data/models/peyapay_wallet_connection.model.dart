class PeyapayWalletConnection {
  const PeyapayWalletConnection({
    this.gsmPrincipale,
    this.codePaysResidence,
    this.solde,
    this.codeAgence,
  });

  final String? gsmPrincipale;
  final String? codePaysResidence;
  final String? solde;
  final String? codeAgence;

  factory PeyapayWalletConnection.fromJson(Map<String, dynamic> json) {
    return PeyapayWalletConnection(
      gsmPrincipale: json['gsmPrincipale']?.toString(),
      codePaysResidence: json['codePaysResidence']?.toString(),
      solde: json['solde']?.toString(),
      codeAgence: json['codeAgence']?.toString(),
    );
  }
}
