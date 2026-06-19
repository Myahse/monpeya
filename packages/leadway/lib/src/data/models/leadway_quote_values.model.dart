/// Détails de prime retournés par l'API calcule-prime (`resultValue.detailsPrime`).
class LeadwayDetailsPrime {
  const LeadwayDetailsPrime({
    required this.primeNette,
    required this.taxes,
    required this.accessoires,
    required this.cedeao,
    required this.fga,
    required this.primeTtc,
    required this.frais,
  });

  final int primeNette;
  final int taxes;
  final int accessoires;
  final int cedeao;
  final int fga;
  final int primeTtc;
  final double frais;

  factory LeadwayDetailsPrime.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse('$value') ?? 0;
    }

    double readDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return LeadwayDetailsPrime(
      primeNette: readInt(json['primeNette'] ?? json['prime_nette']),
      taxes: readInt(json['taxes']),
      accessoires: readInt(json['accessoires']),
      cedeao: readInt(json['cedeao']),
      fga: readInt(json['fga']),
      primeTtc: readInt(json['primeTTC'] ?? json['primeTtc'] ?? json['prime_ttc']),
      frais: readDouble(json['frais']),
    );
  }

  Map<String, dynamic> toJson() => {
        'primeNette': primeNette,
        'taxes': taxes,
        'accessoires': accessoires,
        'cedeao': cedeao,
        'fga': fga,
        'primeTTC': primeTtc,
        'frais': frais,
      };
}

/// Liste des garanties retournée par l'API calcule-prime (`resultValue.listeGaranties`).
class LeadwayListeGaranties {
  const LeadwayListeGaranties({
    required this.garantieRC,
    required this.garantieDefenseRecours,
    required this.garantieBrisDeGlace,
    required this.garantieIncendie,
    required this.garantieVol,
    required this.garantieVolAccessoires,
    required this.garantieDommageCollision,
    required this.garantieDommagesTousAccidents,
    required this.garantieRecoursAnticipe,
    required this.garantieAssistanceAuto,
    required this.garantieVie,
    required this.garantieSecuriteRoutiere,
  });

  final int garantieRC;
  final int garantieDefenseRecours;
  final int garantieBrisDeGlace;
  final int garantieIncendie;
  final int garantieVol;
  final int garantieVolAccessoires;
  final int garantieDommageCollision;
  final int garantieDommagesTousAccidents;
  final int garantieRecoursAnticipe;
  final int garantieAssistanceAuto;
  final int garantieVie;
  final int garantieSecuriteRoutiere;

  factory LeadwayListeGaranties.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse('$value') ?? 0;
    }

    return LeadwayListeGaranties(
      garantieRC: readInt(json['garantieRC']),
      garantieDefenseRecours: readInt(json['garantieDefenseRecours']),
      garantieBrisDeGlace: readInt(json['garantieBrisDeGlace']),
      garantieIncendie: readInt(json['garantieIncendie']),
      garantieVol: readInt(json['garantieVol']),
      garantieVolAccessoires: readInt(json['garantieVolAccessoires']),
      garantieDommageCollision: readInt(json['garantieDommageCollision']),
      garantieDommagesTousAccidents: readInt(json['garantieDommagesTousAccidents']),
      garantieRecoursAnticipe: readInt(json['garantieRecoursAnticipe']),
      garantieAssistanceAuto: readInt(json['garantieAssistanceAuto']),
      garantieVie: readInt(json['garantieVie']),
      garantieSecuriteRoutiere: readInt(json['garantieSecuriteRoutiere']),
    );
  }

  Map<String, dynamic> toJson() => {
        'garantieRC': garantieRC,
        'garantieDefenseRecours': garantieDefenseRecours,
        'garantieBrisDeGlace': garantieBrisDeGlace,
        'garantieIncendie': garantieIncendie,
        'garantieVol': garantieVol,
        'garantieVolAccessoires': garantieVolAccessoires,
        'garantieDommageCollision': garantieDommageCollision,
        'garantieDommagesTousAccidents': garantieDommagesTousAccidents,
        'garantieRecoursAnticipe': garantieRecoursAnticipe,
        'garantieAssistanceAuto': garantieAssistanceAuto,
        'garantieVie': garantieVie,
        'garantieSecuriteRoutiere': garantieSecuriteRoutiere,
      };
}

/// Contenu de `resultValue` conservé pour la création du devis (`quoteValues`).
class LeadwayQuoteValues {
  const LeadwayQuoteValues({
    required this.detailsPrime,
    required this.listeGaranties,
  });

  final LeadwayDetailsPrime detailsPrime;
  final LeadwayListeGaranties listeGaranties;

  factory LeadwayQuoteValues.fromJson(Map<String, dynamic> json) {
    final details = json['detailsPrime'];
    final garanties = json['listeGaranties'];
    if (details is! Map || garanties is! Map) {
      throw FormatException('resultValue invalide: $json');
    }
    return LeadwayQuoteValues(
      detailsPrime: LeadwayDetailsPrime.fromJson(Map<String, dynamic>.from(details)),
      listeGaranties: LeadwayListeGaranties.fromJson(Map<String, dynamic>.from(garanties)),
    );
  }

  Map<String, dynamic> toJson() => {
        'detailsPrime': detailsPrime.toJson(),
        'listeGaranties': listeGaranties.toJson(),
      };
}
