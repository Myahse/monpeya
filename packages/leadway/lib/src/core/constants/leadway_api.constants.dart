/// Produits d'assurance
enum LeadwayProductCode {
  tiersSimple('TIERS_SIMPLE', 'Tiers Simple', 'Responsabilité civile uniquement'),
  tiersComplet('TIERS_COMPLET', 'Tiers Complet', 'RC + Défense et Recours'),
  tousRisques('TOUS_RISQUES', 'Tous Risques', 'Couverture complète (dommages, vol, incendie)'),
  surMesure('SUR_MESURE', 'Sur Mesure', 'Garanties au choix');
  //tiersSimpleMoto('TIERS_SIMPLE_MOTO', 'Tiers Simple Moto', 'RC moto uniquement');

  const LeadwayProductCode(this.code, this.name, this.description);
  final String code;
  final String name;
  final String description;
}

/// Catégories de véhicules
enum LeadwayVehicleCategory {
  particular(1, 'Véhicule particulier', 'Voiture personnelle'),
  camionLight(2, 'Camion 2-3.5 tonnes', 'Utilitaire léger'),
  camionMedium(3, 'Camion 3.5-7.5 tonnes', 'Poids moyen'),
  taxi(4, 'VTC / Taxi', 'Transport de personnes'),
  moto(5, 'Moto', 'Deux-roues, trois-roues'),
  motoLight(6, 'Moto légère', 'Cyclomoteur, scooter'),
  camionnette(7, 'Camionnette', 'Transport marchandises'),
  poidsLourd(8, 'Poids lourd', 'Transport commercial'),
  remorque(9, 'Remorque', 'Semi-remorque'),
  bus(10, 'Ambulance / Bus', 'Transport collectif'),
  professional(12, 'Véhicule de société', 'Usage professionnel');

  const LeadwayVehicleCategory(this.value, this.type, this.example);
  final int value;
  final String type;
  final String example;
}

/// Types d'énergie
enum LeadwayEnergy {
  essence('ESSENCE', 'Essence'),
  diesel('DIESEL', 'Diesel'),
  electric('ELECTRIC', 'Électrique');

  const LeadwayEnergy(this.code, this.name);
  final String code;
  final String name;
}

/// Garanties
enum LeadwayWarranty {
  rc('garantieRC', 'Responsabilité Civile'),
  defenseRecours('garantieDefenseRecours', 'Défense et Recours'),
  brisDeGlace('garantieBrisDeGlace', 'Bris de Glace'),
  incendie('garantieIncendie', 'Incendie'),
  vol('garantieVol', 'Vol'),
  volAccessoires('garantieVolAccessoires', 'Vol d\'Accessoires'),
  dommageCollision('garantieDommageCollision', 'Dommages Collision'),
  dommagesTousAccidents('garantieDommagesTousAccidents', 'Dommages Tous Accidents'),
  recoursAnticipe('garantieRecoursAnticipe', 'Recours Anticipé'),
  assistanceAuto('garantieAssistanceAuto', 'Assistance Auto'),
  vie('garantieVie', 'Garantie Vie'),
  securiteRoutiere('garantieSecuriteRoutiere', 'Sécurité Routière');

  const LeadwayWarranty(this.code, this.name);
  final String code;
  final String name;
}

/// Niveaux d'assistance
enum LeadwayAssistanceLevel {
  none(0, 'Sans assistance'),
  basic(1, 'Assistance de base'),
  extended(2, 'Assistance étendue'),
  premium(3, 'Assistance premium');

  const LeadwayAssistanceLevel(this.value, this.description);
  final int value;
  final String description;
}

/// Durées de contrat autorisées (en jours)
enum LeadwayContractDuration {
  unMois(30, '1 Mois (30 jours)'),
  troisMois(91, '3 Mois (91 jours)'),
  sixMois(183, '6 Mois (183 jours)'),
  douzeMois(365, '12 Mois (365 jours)');

  const LeadwayContractDuration(this.days, this.label);
  final int days;
  final String label;
}

/// Genres véhicule catégorie 6 (Moto légère / Cyclomoteur)
enum LeadwayGenreCategory6 {
  autres23Roues('AUTRES_VEH_2_3_ROUES', 'Autres véhicules 2-3 roues'),
  veh4Roues('VEH_4_ROUES', 'Véhicules 4 roues'),
  cyclomoteur('CYCLOMOTEUR', 'Cyclomoteur');

  const LeadwayGenreCategory6(this.code, this.description);
  final String code;
  final String description;
}

/// États du devis
enum LeadwayQuoteState {
  draft('Draft', 'Brouillon'),
  pendingReview('Pending_Review', 'En attente de révision'),
  underReview('Under_Review', 'En cours de révision'),
  additionalInfoRequired('Additional_Information_Required', 'Informations complémentaires requises'),
  approved('Approved', 'Approuvé'),
  rejected('Rejected', 'Rejeté'),
  quotationSent('Quotation_Sent', 'Devis envoyé'),
  accepted('Accepted', 'Accepté'),
  policyIssued('Policy_Issued', 'Police émise'),
  expired('Expired', 'Expiré'),
  cancelled('Cancelled', 'Annulé');

  const LeadwayQuoteState(this.code, this.description);
  final String code;
  final String description;
}

/// Catégories socio-professionnelles client
enum LeadwaySocioCategory {
  defaultCategory('Default', 'Par défaut'),
  employe('EMPLOYE', 'Employé / Salarié'),
  commercant('COMMERCANT', 'Commerçant'),
  retraite('RETRAITE', 'Retraité'),
  etudiant('ETUDIANT', 'Étudiant'),
  artisan('ARTISAN', 'Artisan / Indépendant'),
  autre('AUTRE', 'Autre');

  const LeadwaySocioCategory(this.code, this.label);
  final String code;
  final String label;
}

/// Genres véhicule catégorie 7 (Camionnette)
enum LeadwayGenreCategory7 {
  tourisme('VEHICULE_DE_TOURISME', 'Véhicule de tourisme'),
  utilitaire('VEHICULE_UTILITAIRE', 'Véhicule utilitaire');

  const LeadwayGenreCategory7(this.code, this.description);
  final String code;
  final String description;
}

/// Genres véhicule catégorie 8 (Poids lourd)
enum LeadwayGenreCategory8 {
  tourisme('VEHICULE_TOURISME', 'Véhicule de tourisme'),
  cat2('VEHICULE_CAT2', 'Véhicule Catégorie 2'),
  cat3('VEHICULE_CAT3', 'Véhicule Catégorie 3');

  const LeadwayGenreCategory8(this.code, this.description);
  final String code;
  final String description;
}

/// Genres véhicule catégorie 10 (Bus / Ambulance)
enum LeadwayGenreCategory10 {
  ambCorFour('AMB_COR_FOUR', 'Ambulance / Corbillard'),
  vehCollPublique('VEH_COLL_PUBLIQUE', 'Véhicule Collectivité Publique');

  const LeadwayGenreCategory10(this.code, this.description);
  final String code;
  final String description;
}

/// Types de véhicule
enum LeadwayVehicleType {
  auto('auto', 'Voiture'),
  moto('moto', 'Moto');

  const LeadwayVehicleType(this.code, this.description);
  final String code;
  final String description;
}

/// Opérateurs de paiement (codes API en minuscules).
abstract class LeadwayPaymentOperator {
  static const orange = 'orange';
  static const peyapay = 'peyapay';
  static const mtn = 'mtn';
  static const moov = 'moov';
  static const wave = 'wave';
}

/// Valeurs par défaut pour l'initiation du paiement.
abstract class LeadwayPaymentDefaults {
  static const agentCode = '0';
  static const deliveryLocation = 'Abidjan';
}
