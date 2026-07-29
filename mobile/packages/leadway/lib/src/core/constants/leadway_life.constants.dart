/// Codes produit Assurance Vie Leadway.
enum LeadwayLifeProductCode {
  funerairesDjogana('FUNERAIRES_DJOGANA', 'Produit Funérailles'),
  bnbDjogana('BNB_DJOGANA', 'Produit Épargne');

  const LeadwayLifeProductCode(this.code, this.label);
  final String code;
  final String label;

  static LeadwayLifeProductCode? fromCode(String? code) {
    if (code == null) return null;
    for (final p in values) {
      if (p.code == code) return p;
    }
    return null;
  }
}

/// Genre (API Vie).
enum LeadwayLifeGender {
  male('MALE', 'Homme'),
  female('FEMALE', 'Femme');

  const LeadwayLifeGender(this.code, this.label);
  final String code;
  final String label;
}

/// Lien de parenté avec le souscripteur.
enum LeadwayLifeRelationship {
  self('SELF', 'Soi-même'),
  father('FATHER', 'Père'),
  mother('MOTHER', 'Mère'),
  spouse('SPOUSE', 'Époux / Épouse'),
  child('CHILD', 'Enfant'),
  sibling('SIBLING', 'Frère / Sœur');

  const LeadwayLifeRelationship(this.code, this.label);
  final String code;
  final String label;

  static LeadwayLifeRelationship? fromCode(String? code) {
    if (code == null) return null;
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// Fréquence de paiement.
enum LeadwayLifePaymentFrequency {
  daily('DAILY', 'Journalière'),
  weekly('WEEKLY', 'Hebdomadaire'),
  monthly('MONTHLY', 'Mensuelle'),
  quarterly('QUARTERLY', 'Trimestrielle'),
  annual('ANNUAL', 'Annuelle'),
  yearly('YEARLY', 'Annuelle');

  const LeadwayLifePaymentFrequency(this.code, this.label);
  final String code;
  final String label;

  static LeadwayLifePaymentFrequency? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final c = code.toUpperCase();
    if (c == 'ANNUAL') return annual;
    if (c == 'YEARLY') return yearly;
    for (final f in values) {
      if (f.code == c) return f;
    }
    return null;
  }
}

/// Grille tarifaire FUNERAIRES_DJOGANA (FCFA) par fréquence.
abstract class LeadwayLifeFunerairesTariff {
  static const Map<String, int> amountsByFrequency = {
    'DAILY': 100,
    'WEEKLY': 500,
    'MONTHLY': 2000,
    'ANNUAL': 12000,
    'YEARLY': 12000,
  };

  static bool appliesTo(String productCode) =>
      productCode.toUpperCase() == LeadwayLifeProductCode.funerairesDjogana.code;

  static int? amountFor(String? paymentFrequency) {
    if (paymentFrequency == null || paymentFrequency.isEmpty) return null;
    return amountsByFrequency[paymentFrequency.toUpperCase()];
  }

  /// Enrichit les enums fréquence avec le montant de la grille.
  static List<LeadwayLifeEnumItem> enrichFrequencies(List<LeadwayLifeEnumItem> items) {
    return items.map((e) {
      final amount = amountFor(e.value);
      if (amount == null) return e;
      final base = e.description.trim().isNotEmpty ? e.description : e.value;
      return LeadwayLifeEnumItem(
        value: e.value,
        description: '$base — ${_formatAmount(amount)} FCFA',
      );
    }).toList();
  }

  static String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Statuts de souscription Vie (filtre GET /api/souscription).
enum LeadwayLifeSubscriptionStatus {
  draft('DRAFT', 'Brouillon'),
  quoted('QUOTED', 'Coté'),
  created('CREATED', 'Créée'),
  failed('FAILED', 'Échouée'),
  cancelled('CANCELLED', 'Annulée'),
  expired('EXPIRED', 'Expirée');

  const LeadwayLifeSubscriptionStatus(this.code, this.label);
  final String code;
  final String label;

  static LeadwayLifeSubscriptionStatus? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final s in values) {
      if (s.code == code.toUpperCase()) return s;
    }
    return null;
  }
}

/// Statuts paiement récurrent (filtre GET /api/souscription/paiement-recurrent).
enum LeadwayLifeRecurringPaymentStatus {
  pending('PENDING', 'En attente'),
  processing('PROCESSING', 'En cours'),
  completed('COMPLETED', 'Terminé'),
  failed('FAILED', 'Échoué'),
  cancelled('CANCELLED', 'Annulé');

  const LeadwayLifeRecurringPaymentStatus(this.code, this.label);
  final String code;
  final String label;

  static LeadwayLifeRecurringPaymentStatus? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final s in values) {
      if (s.code == code.toUpperCase()) return s;
    }
    return null;
  }
}

/// Entrée d'énumération renvoyée par GET /api/enums/*
class LeadwayLifeEnumItem {
  const LeadwayLifeEnumItem({
    required this.value,
    required this.description,
  });

  final String value;
  final String description;

  factory LeadwayLifeEnumItem.fromJson(Map<String, dynamic> json) {
    return LeadwayLifeEnumItem(
      value: json['value']?.toString() ?? '',
      description: (json['description']?.toString().trim().isNotEmpty == true)
          ? json['description'].toString()
          : (json['value']?.toString() ?? ''),
    );
  }
}
