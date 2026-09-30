class SimDevisRequest {
  const SimDevisRequest({
    required this.produit,
    this.formule,
    this.nombrePeriodes,
  });

  final String produit;
  final String? formule;
  final int? nombrePeriodes;

  Map<String, dynamic> toJson() {
    return {
      'produit': produit,
      if (formule != null) 'formule': formule,
      if (nombrePeriodes != null) 'nombrePeriodes': nombrePeriodes,
    };
  }
}

class SimDevisResult {
  const SimDevisResult({
    required this.prime,
    required this.primeUnitaire,
    required this.commissionMontant,
    required this.montantAReverser,
    required this.delaiAttente72h,
  });

  final int prime;
  final int primeUnitaire;
  final int commissionMontant;
  final int montantAReverser;
  final bool delaiAttente72h;

  factory SimDevisResult.fromJson(Map<String, dynamic> json) {
    final commission = json['commissionApi'];
    final priseEffet = json['priseEffet'];
    return SimDevisResult(
      prime: (json['prime'] as num?)?.toInt() ?? 0,
      primeUnitaire: (json['primeUnitaire'] as num?)?.toInt() ?? 0,
      commissionMontant: commission is Map ? (commission['montant'] as num?)?.toInt() ?? 0 : 0,
      montantAReverser: commission is Map ? (commission['montantAReverser'] as num?)?.toInt() ?? 0 : 0,
      delaiAttente72h: priseEffet is Map ? priseEffet['delaiAttente72h'] == true : false,
    );
  }
}
