/// Nested `wtypeClient` object from PeyaPay (`/wClients/*`).
class PeyapayTypeClient {
  const PeyapayTypeClient({
    this.idwTypeClient,
    this.codeLibClt,
    this.estFournisseur,
    this.afficher,
    this.ncg,
  });

  final int? idwTypeClient;
  final String? codeLibClt;
  final String? estFournisseur;
  final String? afficher;
  final String? ncg;

  bool get isClientLabel =>
      codeLibClt?.toUpperCase().contains('CLIENT') == true;

  factory PeyapayTypeClient.fromJson(Map<String, dynamic> json) {
    return PeyapayTypeClient(
      idwTypeClient: json['idwTypeClient'] is int
          ? json['idwTypeClient'] as int
          : int.tryParse('${json['idwTypeClient']}'),
      codeLibClt: json['codeLibClt']?.toString(),
      estFournisseur: json['estFournisseur']?.toString(),
      afficher: json['afficher']?.toString(),
      ncg: json['ncg']?.toString(),
    );
  }

  static List<String> readTypcptsFromAccounts(Object? accounts) {
    if (accounts is! List) return const [];
    final out = <String>[];
    for (final row in accounts) {
      if (row is! Map) continue;
      final typcpt = row['typcpt']?.toString().trim();
      if (typcpt != null && typcpt.isNotEmpty) out.add(typcpt);
    }
    return out;
  }
}
