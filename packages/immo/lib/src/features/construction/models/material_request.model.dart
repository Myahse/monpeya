/// A demande as `/api/demandes/entreprise/{userId}` returns it (DemandeResumeDto).
class MaterialRequest {
  const MaterialRequest({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.justification,
    this.budget,
    this.urgency,
    this.createdAt,
    this.validatedAt,
    this.siteId,
    this.siteName,
    this.type,
    this.category,
    this.items = const [],
    this.supplierName,
    this.orderNumber,
    this.orderedAt,
    this.shippedAt,
    this.expectedOn,
    this.deliveredAt,
    this.receivedAt,
    this.receptionComment,
  });

  final String id;
  final String title;

  /// Backend etat: `en attente`, `validé_superviseur`, `refusé`, `en_cours_moyens_generaux`,
  /// `envoyé_fournisseur`, `en_livraison`, `livré_chantier`, `terminé`, `réception_partielle`…
  final String status;
  final String? description;
  final String? justification;
  final double? budget;
  final String? urgency;
  final DateTime? createdAt;
  final DateTime? validatedAt;
  final String? siteId;
  final String? siteName;
  final String? type;

  /// MATERIAL or FINANCIAL.
  final String? category;
  final List<MaterialRequestItem> items;

  /// Set once the moyens généraux ordered it.
  final String? supplierName;
  final String? orderNumber;
  final DateTime? orderedAt;

  /// Delivery: the supplier set off (expected on [expectedOn]), delivered, then the chef
  /// de chantier checked it on site.
  final DateTime? shippedAt;
  final DateTime? expectedOn;
  final DateTime? deliveredAt;
  final DateTime? receivedAt;
  final String? receptionComment;

  bool get isPending => status == 'en attente' || status == 'en_attente';

  /// "haute", "urgente"… ; null when normal.
  String? get urgencyLabel => switch (urgency?.toUpperCase()) {
        null || '' || 'NORMAL' || 'NORMALE' => null,
        'HAUTE' => 'haute',
        'URGENTE' || 'URGENT' => 'urgente',
        'BASSE' => 'basse',
        final other => other.toLowerCase(),
      };

  bool get isRefused => status.startsWith('refus');

  bool get isMaterial => category == null || category == 'MATERIAL';

  /// Validated (or taken over on the web) and waiting for the moyens généraux to order it.
  bool get isToOrder =>
      isMaterial && (status == 'validé_superviseur' || status == 'en_cours_moyens_generaux');

  /// Ordered and not delivered yet (sent to the supplier, or on its way).
  bool get isOrdered => status == 'envoyé_fournisseur' || isOnItsWay;

  bool get isOnItsWay => status == 'en_livraison';

  /// Delivered; the chef de chantier still has to check it on site.
  bool get isAwaitingReception => status == 'livré_chantier';

  /// Checked on site: everything arrived.
  bool get isReceived => status.startsWith('termin');

  /// Checked on site: something is missing.
  bool get isShort => status == 'réception_partielle';

  bool get isDelivered => isAwaitingReception || isReceived || isShort || status.startsWith('livr');

  /// Still moving through the workflow (not refused, not received in full, not paid).
  bool get isOpen => !isRefused && !isReceived && !status.startsWith('pay');

  String get statusLabel {
    if (isPending) return 'À valider';
    if (isRefused) return 'Refusée';
    if (status == 'validé_superviseur') return 'Validée';
    if (status.contains('moyens_generaux')) return 'En commande';
    if (isOnItsWay) return 'En route';
    if (isOrdered) return 'Commandée';
    if (isAwaitingReception) return 'À réceptionner';
    if (isShort) return 'Réception partielle';
    if (isReceived) return 'Réceptionnée';
    if (isDelivered) return 'Livrée';
    return status;
  }

  factory MaterialRequest.fromBackend(Map<String, dynamic> j) {
    final title = (j['titre'] as String? ?? '').trim();
    return MaterialRequest(
      id: (j['demandesId'] ?? '').toString(),
      title: title.isEmpty ? 'Demande' : title,
      status: (j['etat'] ?? '').toString(),
      description: j['description'] as String?,
      justification: j['justification'] as String?,
      budget: double.tryParse('${j['budgetEstime']}'),
      urgency: j['urgence'] as String?,
      createdAt: DateTime.tryParse('${j['createdAt']}'),
      validatedAt: DateTime.tryParse('${j['dateValidation']}'),
      siteId: j['chantiersId']?.toString(),
      siteName: j['chantierNom'] as String?,
      type: j['typeDemande'] as String?,
      category: j['categorie'] as String?,
      supplierName: j['fournisseurNom'] as String?,
      orderNumber: j['numeroCommande'] as String?,
      orderedAt: DateTime.tryParse('${j['dateCommande']}'),
      shippedAt: DateTime.tryParse('${j['dateExpedition']}'),
      expectedOn: DateTime.tryParse('${j['dateLivraisonPrevue']}'),
      deliveredAt: DateTime.tryParse('${j['dateLivraison']}'),
      receivedAt: DateTime.tryParse('${j['dateReception']}'),
      receptionComment: j['commentaireReception'] as String?,
      items: [
        for (final l in (j['lignes'] as List? ?? const []))
          if (l is Map) MaterialRequestItem.fromBackend(Map<String, dynamic>.from(l)),
      ],
    );
  }
}

class MaterialRequestItem {
  const MaterialRequestItem({
    required this.label,
    required this.quantity,
    this.unit,
    this.amount,
    this.orderLineId,
    this.delivered,
  });

  final String label;
  final int quantity;
  final String? unit;
  final double? amount;

  /// Its order line once ordered: what the chef de chantier checks the delivery against.
  final String? orderLineId;

  /// Delivered, then as counted on site.
  final int? delivered;

  String get quantityLabel => quantityWithUnit(quantity, unit);

  factory MaterialRequestItem.fromBackend(Map<String, dynamic> j) => MaterialRequestItem(
        label: (j['libelle'] ?? '').toString(),
        quantity: (j['quantite'] as num? ?? 0).round(),
        unit: j['unite'] as String?,
        amount: double.tryParse('${j['montant']}'),
        orderLineId: j['commandesId']?.toString(),
        delivered: (j['quantiteLivree'] as num?)?.round(),
      );
}

/// A supplier to order from (`/api/demandes/fournisseurs`).
class Supplier {
  const Supplier({required this.id, required this.name, this.phone, this.specialties, this.type, this.rating});

  final String id;
  final String name;
  final String? phone;
  final String? specialties;
  final String? type;
  final int? rating;

  factory Supplier.fromBackend(Map<String, dynamic> j) => Supplier(
        id: (j['fournisseursId'] ?? '').toString(),
        name: ((j['nom'] as String?)?.trim().isNotEmpty ?? false) ? (j['nom'] as String).trim() : 'Fournisseur',
        phone: j['telephone'] as String?,
        specialties: j['specialites'] as String?,
        type: j['type'] as String?,
        rating: (j['evaluationQualite'] as num?)?.round(),
      );
}

/// `228 sacs`, `21 m³`, `2 012 unités` — the packaging units in the plural.
String quantityWithUnit(int quantity, String? unit) {
  final u = unit ?? '';
  final plural = quantity > 1 ? unitPlural(u) : u;
  final grouped = quantity.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  return '$grouped $plural'.trim();
}

/// `sacs`, `barres`, `unités`; measures (`m³`, `kg`) stay as they are.
String unitPlural(String unit) => const {'sac', 'barre', 'unité'}.contains(unit) ? '${unit}s' : unit;

/// An order as the supplier sees it (`/api/demandes/fournisseur/{userId}/commandes`).
class SupplierOrder {
  const SupplierOrder({
    required this.requestId,
    required this.status,
    this.number,
    this.orderedAt,
    this.siteName,
    this.instruction,
    this.carrier,
    this.shippedAt,
    this.expectedOn,
    this.deliveredAt,
    this.receivedAt,
    this.total,
    this.lines = const [],
  });

  /// The demande it fulfils — what delivery is confirmed against.
  final String requestId;

  /// envoyé_fournisseur (to send), en_livraison (on its way), livré_chantier (delivered),
  /// then terminé or réception_partielle once checked on site.
  final String status;
  final String? number;
  final DateTime? orderedAt;
  final String? siteName;
  final String? instruction;
  final String? carrier;
  final DateTime? shippedAt;
  final DateTime? expectedOn;
  final DateTime? deliveredAt;
  final DateTime? receivedAt;
  final double? total;
  final List<SupplierOrderLine> lines;

  /// Still to deliver: not sent yet, or on its way.
  bool get isToDeliver => status == 'envoyé_fournisseur' || isOnItsWay;

  bool get isOnItsWay => status == 'en_livraison';

  bool get isDelivered => !isToDeliver && (status.startsWith('termin') || status.startsWith('livr') || isShort);

  bool get isShort => status == 'réception_partielle';

  String get statusLabel => switch (status) {
        'envoyé_fournisseur' => 'À livrer',
        'en_livraison' => 'En route',
        'réception_partielle' => 'Réception partielle',
        _ when status.startsWith('termin') => 'Réceptionnée',
        _ => 'Livrée',
      };

  factory SupplierOrder.fromBackend(Map<String, dynamic> j) => SupplierOrder(
        requestId: (j['demandesId'] ?? '').toString(),
        status: (j['etat'] ?? '').toString(),
        number: j['numeroCommande'] as String?,
        orderedAt: DateTime.tryParse('${j['dateCommande']}'),
        siteName: j['chantierNom'] as String?,
        instruction: j['instructionLivraison'] as String?,
        carrier: j['transporteur'] as String?,
        shippedAt: DateTime.tryParse('${j['dateExpedition']}'),
        expectedOn: DateTime.tryParse('${j['dateLivraisonPrevue']}'),
        deliveredAt: DateTime.tryParse('${j['dateLivraison']}'),
        receivedAt: DateTime.tryParse('${j['dateReception']}'),
        total: double.tryParse('${j['montantTotal']}'),
        lines: [
          for (final l in (j['lignes'] as List? ?? const []))
            if (l is Map) SupplierOrderLine.fromBackend(Map<String, dynamic>.from(l)),
        ],
      );
}

class SupplierOrderLine {
  const SupplierOrderLine({
    required this.label,
    required this.ordered,
    this.delivered = 0,
    this.unit,
    this.amount,
    this.orderLineId,
  });

  final String label;
  final int ordered;

  /// As delivered, then as counted on site.
  final int delivered;
  final String? unit;
  final double? amount;
  final String? orderLineId;

  String get quantityLabel => quantityWithUnit(ordered, unit);

  factory SupplierOrderLine.fromBackend(Map<String, dynamic> j) => SupplierOrderLine(
        label: (j['libelle'] ?? '').toString(),
        ordered: (j['quantiteCommandee'] as num? ?? 0).round(),
        delivered: (j['quantiteLivree'] as num? ?? 0).round(),
        unit: j['unite'] as String?,
        amount: double.tryParse('${j['montant']}'),
        orderLineId: j['commandesId']?.toString(),
      );
}
