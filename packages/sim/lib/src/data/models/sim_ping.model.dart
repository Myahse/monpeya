class SimPingResult {
  const SimPingResult({
    required this.environnement,
    required this.scopes,
    this.partenaireNom,
  });

  final String environnement;
  final List<String> scopes;
  final String? partenaireNom;

  factory SimPingResult.fromJson(Map<String, dynamic> json) {
    final partenaire = json['partenaire'];
    return SimPingResult(
      environnement: json['environnement']?.toString() ?? '',
      scopes: (json['scopes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      partenaireNom: partenaire is Map ? partenaire['nomCommerce']?.toString() : null,
    );
  }
}
