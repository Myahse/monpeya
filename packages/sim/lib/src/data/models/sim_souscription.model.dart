class SimProspect {
  const SimProspect({
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.dateNaissance,
    this.sexe,
  });

  final String nom;
  final String prenom;
  final String telephone;
  final String? dateNaissance;
  final String? sexe;

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        if (dateNaissance != null) 'dateNaissance': dateNaissance,
        if (sexe != null) 'sexe': sexe,
      };
}

class SimSouscriptionRequest {
  const SimSouscriptionRequest({
    required this.produit,
    required this.formule,
    required this.prospect,
    required this.pieceIdentiteUrl,
    required this.selfieUrl,
    this.nombrePeriodes,
  });

  final String produit;
  final String formule;
  final SimProspect prospect;
  final String pieceIdentiteUrl;
  final String selfieUrl;
  final int? nombrePeriodes;

  Map<String, dynamic> toJson() => {
        'produit': produit,
        'formule': formule,
        if (nombrePeriodes != null) 'nombrePeriodes': nombrePeriodes,
        'prospect': prospect.toJson(),
        'pieceIdentiteUrl': pieceIdentiteUrl,
        'selfieUrl': selfieUrl,
      };
}

class SimSouscriptionResult {
  const SimSouscriptionResult({
    required this.id,
    required this.statut,
    required this.montantAPercevoir,
    required this.montantCommissionApi,
    required this.montantAReverser,
  });

  final String id;
  final String statut;
  final int montantAPercevoir;
  final int montantCommissionApi;
  final int montantAReverser;

  factory SimSouscriptionResult.fromJson(Map<String, dynamic> json) {
    return SimSouscriptionResult(
      id: json['id']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      montantAPercevoir: (json['montantAPercevoir'] as num?)?.toInt() ?? 0,
      montantCommissionApi: (json['montantCommissionApi'] as num?)?.toInt() ?? 0,
      montantAReverser: (json['montantAReverser'] as num?)?.toInt() ?? 0,
    );
  }
}
