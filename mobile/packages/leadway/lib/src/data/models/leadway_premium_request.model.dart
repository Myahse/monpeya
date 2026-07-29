import 'package:leadway/src/core/constants/leadway_api.constants.dart';

class LeadwayPremiumRequest {
  const LeadwayPremiumRequest({
    required this.cotation,
  });

  final LeadwayCotation cotation;

  /// Construit le payload API à partir des champs essentiels du formulaire.
  factory LeadwayPremiumRequest.fromForm({
    required int ageVehicule,
    required int valeurInitiale,
    required int valeurVenale,
    required LeadwayProductCode codeProduit,
    required LeadwayVehicleCategory categorieVehicule,
    required int dureeContratEnJour,
    required bool isVehiculeVTC,
    required bool isGPS,
    required bool garantieSecuriteRoutiere,
    required int garantieAssistanceAuto,
    required bool garantieVol,
    required bool garantieVolAccessoires,
    required bool garantieIncendie,
    required bool garantieBrisDeGlace,
    required bool garantieRecoursAnticipe,
    required int chargeUtile,
    required bool isTransportHydro,
    required bool isTracteurRoutier,
    required bool withRecoursAnticipe,
  }) {
    return LeadwayPremiumRequest(
      cotation: LeadwayCotation(
        vehicule: LeadwayVehicule(
          codeProduit: codeProduit,
          categorieVehicule: categorieVehicule,
          dureeContratEnJour: dureeContratEnJour,
          valeurInitiale: valeurInitiale,
          valeurVenale: valeurVenale,
          energie: LeadwayEnergy.essence,
          puissanceFiscale: 2,
          ageVehicule: ageVehicule.clamp(0, 100),
          nombreDePlaces: 2,
          isVehiculeVTC: isVehiculeVTC,
          isGPS: isGPS,
          garantieSecuriteRoutiere: garantieSecuriteRoutiere,
          garantieAssistanceAuto: garantieAssistanceAuto,
          garantieVol: garantieVol,
          garantieVolAccessoires: garantieVolAccessoires,
          garantieIncendie: garantieIncendie,
          garantieBrisDeGlace: garantieBrisDeGlace,
          garantieRecoursAnticipe: garantieRecoursAnticipe,
          cylindree: 125,
          isTricycle: false,
          chargeUtile: chargeUtile,
          isTransportHydro: isTransportHydro,
          isTracteurRoutier: isTracteurRoutier,
          isRemorque: false,
          isDoubleCommande: false,
          genre6: LeadwayGenreCategory6.cyclomoteur.code,
          genre7: 'VEHICULE_DE_TOURISME',
          genre8: 'VEHICULE_TOURISME',
          genre10: 'AMB_COR_FOUR',
          nombreDeCartes: 1,
          withRecoursAnticipe: withRecoursAnticipe,
        ),
        client: const LeadwayClient(
          categorieSocioProfessionnelle: 'Default',
          bonificationPourNonSinistre: '0',
          reductionCommerciale: '0',
          reductionFlotte: '0',
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'cotation': cotation.toJson(),
      };
}

class LeadwayCotation {
  const LeadwayCotation({
    required this.vehicule,
    required this.client,
  });

  final LeadwayVehicule vehicule;
  final LeadwayClient client;

  Map<String, dynamic> toJson() => {
        'vehicule': vehicule.toJson(),
        'client': client.toJson(),
      };
}

class LeadwayVehicule {
  const LeadwayVehicule({
    required this.codeProduit,
    required this.categorieVehicule,
    required this.dureeContratEnJour,
    required this.valeurInitiale,
    required this.valeurVenale,
    required this.energie,
    required this.puissanceFiscale,
    required this.ageVehicule,
    required this.nombreDePlaces,
    required this.isVehiculeVTC,
    required this.isGPS,
    required this.garantieSecuriteRoutiere,
    required this.garantieAssistanceAuto,
    required this.garantieVol,
    required this.garantieVolAccessoires,
    required this.garantieIncendie,
    required this.garantieBrisDeGlace,
    required this.garantieRecoursAnticipe,
    required this.cylindree,
    required this.isTricycle,
    required this.chargeUtile,
    required this.isTransportHydro,
    required this.isTracteurRoutier,
    required this.isRemorque,
    required this.isDoubleCommande,
    required this.genre6,
    required this.genre7,
    required this.genre8,
    required this.genre10,
    required this.nombreDeCartes,
    required this.withRecoursAnticipe,
  });

  final LeadwayProductCode codeProduit;
  final LeadwayVehicleCategory categorieVehicule;
  final int dureeContratEnJour;
  final int valeurInitiale;
  final int valeurVenale;
  final LeadwayEnergy energie;
  final int puissanceFiscale;
  final int ageVehicule;
  final int nombreDePlaces;
  final bool isVehiculeVTC;
  final bool isGPS;
  final bool garantieSecuriteRoutiere;
  final int garantieAssistanceAuto;
  final bool garantieVol;
  final bool garantieVolAccessoires;
  final bool garantieIncendie;
  final bool garantieBrisDeGlace;
  final bool garantieRecoursAnticipe;
  final int cylindree;
  final bool isTricycle;
  final int chargeUtile;
  final bool isTransportHydro;
  final bool isTracteurRoutier;
  final bool isRemorque;
  final bool isDoubleCommande;
  final String genre6;
  final String genre7;
  final String genre8;
  final String genre10;
  final int nombreDeCartes;
  final bool withRecoursAnticipe;

  Map<String, dynamic> toJson() {
    final catVal = categorieVehicule.value;
    final map = <String, dynamic>{
      'codeProduit': codeProduit.code,
      'categorieVehicule': catVal,
      'dureeContratEnJour': dureeContratEnJour,
    };

    // 1. valeurInitiale, valeurVenale, ageVehicule, isVehiculeVTC, isGPS, garantieAssistanceAuto
    // Requis pour categories 1-4, 6-10, 12
    if ((catVal >= 1 && catVal <= 4) || (catVal >= 6 && catVal <= 10) || catVal == 12) {
      map['valeurInitiale'] = valeurInitiale;
      map['valeurVenale'] = valeurVenale;
      map['ageVehicule'] = ageVehicule;
      map['isVehiculeVTC'] = isVehiculeVTC;
      map['isGPS'] = isGPS;
      map['garantieAssistanceAuto'] = garantieAssistanceAuto;
    }

    // 2. energie, puissanceFiscale
    // Requis pour categories 1, 7, 8, 10, 12
    if (catVal == 1 || catVal == 7 || catVal == 8 || catVal == 10 || catVal == 12) {
      map['energie'] = energie.code;
      map['puissanceFiscale'] = puissanceFiscale;
    }

    // 3. nombreDePlaces
    // Requis pour categories 1, 4, 5, 6, 10
    if (catVal == 1 || catVal == 4 || catVal == 5 || catVal == 6 || catVal == 10) {
      map['nombreDePlaces'] = nombreDePlaces;
    }

    // 4. garantieSecuriteRoutiere
    // Requis pour SUR_MESURE, TOUS_RISQUES, TIERS_COMPLET
    if (codeProduit == LeadwayProductCode.surMesure ||
        codeProduit == LeadwayProductCode.tousRisques ||
        codeProduit == LeadwayProductCode.tiersComplet) {
      map['garantieSecuriteRoutiere'] = garantieSecuriteRoutiere;
    }

    // 5. Sur Mesure optionnels
    if (codeProduit == LeadwayProductCode.surMesure) {
      map['garantieVol'] = garantieVol;
      map['garantieVolAccessoires'] = garantieVolAccessoires;
      map['garantieIncendie'] = garantieIncendie;
      map['garantieBrisDeGlace'] = garantieBrisDeGlace;
      map['garantieRecoursAnticipe'] = garantieRecoursAnticipe;
    }

    // 6. cylindree, isTricycle
    // Requis pour categorie 5
    if (catVal == 5) {
      map['cylindree'] = cylindree;
      map['isTricycle'] = isTricycle;
    }

    // 7. chargeUtile
    // Requis pour categories 2, 3, 7, 8, 10
    if (catVal == 2 || catVal == 3 || catVal == 7 || catVal == 8 || catVal == 10) {
      map['chargeUtile'] = chargeUtile;
    }

    // 8. isTransportHydro
    // Requis pour categories 2, 3, 10
    if (catVal == 2 || catVal == 3 || catVal == 10) {
      map['isTransportHydro'] = isTransportHydro;
    }

    // 9. isTracteurRoutier
    // Requis pour categories 2, 3, 8
    if (catVal == 2 || catVal == 3 || catVal == 8) {
      map['isTracteurRoutier'] = isTracteurRoutier;
    }

    // 10. isRemorque
    // Requis pour categorie 9
    if (catVal == 9) {
      map['isRemorque'] = isRemorque;
    }

    // 11. isDoubleCommande
    // Requis pour categorie 7
    if (catVal == 7) {
      map['isDoubleCommande'] = isDoubleCommande;
    }

    // 12. genre6, nombreDeCartes
    // Requis pour categorie 6
    if (catVal == 6) {
      map['genre6'] = genre6.isEmpty ? LeadwayGenreCategory6.cyclomoteur.code : genre6;
      map['nombreDeCartes'] = nombreDeCartes;
    }

    // 13. genre7
    // Requis pour categorie 7
    if (catVal == 7) {
      map['genre7'] = genre7.isEmpty ? 'VEHICULE_DE_TOURISME' : genre7;
    }

    // 14. genre8
    // Requis pour categorie 8
    if (catVal == 8) {
      map['genre8'] = genre8.isEmpty ? 'VEHICULE_TOURISME' : genre8;
    }

    // 15. genre10
    // Requis pour categorie 10
    if (catVal == 10) {
      map['genre10'] = genre10.isEmpty ? 'AMB_COR_FOUR' : genre10;
    }

    // 16. withRecoursAnticipe
    map['withRecoursAnticipe'] = withRecoursAnticipe;

    return map;
  }
}

class LeadwayClient {
  const LeadwayClient({
    required this.categorieSocioProfessionnelle,
    required this.bonificationPourNonSinistre,
    required this.reductionCommerciale,
    required this.reductionFlotte,
  });

  final String categorieSocioProfessionnelle;
  final String bonificationPourNonSinistre;
  final String reductionCommerciale;
  final String reductionFlotte;

  Map<String, dynamic> toJson() => {
        'categorieSocioProfessionnelle': categorieSocioProfessionnelle,
        'bonificationPourNonSinistre': bonificationPourNonSinistre,
        'reductionCommerciale': reductionCommerciale,
        'reductionFlotte': reductionFlotte,
      };
}
