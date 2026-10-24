/// A lease (`/api/contratslocation`), as Mes documents and its detail show it.
class RentalContract {
  const RentalContract({
    required this.id,
    required this.title,
    required this.status,
    this.number,
    this.propertyId,
    this.propertyName,
    this.propertyAddress,
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.ownerId,
    this.rentAmount,
    this.deposit,
    this.agencyFees,
    this.paymentMode,
    this.periodicity,
    this.startDate,
    this.endDate,
    this.tenantSignedAt,
    this.ownerSignedAt,
    this.pdfPath,
    this.terminationRequested = false,
    this.terminationEndOn,
    this.terminationReason,
    this.terminationRequestedAt,
    this.terminationApproved = false,
    this.ownerNotes,
    this.documentType = 'Contrat de location',
  });

  final String id;
  final String title;

  /// Backend statut: `en attente`, `signé`, `résilié`, `annulé`, `expiré`.
  final String status;

  /// `CONTLOC-2026-00001`.
  final String? number;
  final String? propertyId;
  final String? propertyName;
  final String? propertyAddress;
  final String? tenantId;
  final String? tenantName;
  final String? tenantPhone;

  /// The owner (utilisateursId) who signs as bailleur.
  final String? ownerId;
  final double? rentAmount;
  final double? deposit;
  final double? agencyFees;

  /// `mobile_money`, `virement`, `espèces`, `cheque`.
  final String? paymentMode;

  /// `journalier`, `mensuel`, `trimestriel`, `semestriel`, `annuel`.
  final String? periodicity;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? tenantSignedAt;
  final DateTime? ownerSignedAt;

  /// `/api/contratslocation/{id}/pdf`, resolved against the API base URL.
  final String? pdfPath;

  /// Early termination the tenant asked for, then the owner's answer.
  final bool terminationRequested;
  final DateTime? terminationEndOn;
  final String? terminationReason;
  final DateTime? terminationRequestedAt;
  final bool terminationApproved;
  final String? ownerNotes;
  final String documentType;

  bool get isToSign => status == 'en attente';
  bool get isTerminated => status.startsWith('résili');
  bool get isCancelled => status.startsWith('annul');
  bool get isSignedByBoth => tenantSignedAt != null && ownerSignedAt != null;

  /// The tenant asked to leave early and the owner has not answered yet.
  bool get isTerminationPending => terminationRequested && !terminationApproved && !isTerminated;

  bool get _ended {
    final end = endDate;
    if (end == null) return false;
    final today = DateTime.now();
    return end.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Signed (or terminated) and still running.
  bool get isActive => (status == 'signé' || isTerminated) && !_ended;

  String get statusLabel {
    if (isToSign) return 'À signer';
    if (isCancelled) return 'Annulé';
    if (isTerminationPending) return 'Résiliation demandée';
    if (isTerminated) return _ended ? 'Terminé' : 'Résilié';
    if (status == 'signé') return _ended ? 'Terminé' : 'Actif';
    if (status.startsWith('expir')) return 'Terminé';
    return status.isEmpty ? '—' : status;
  }

  String? get paymentModeLabel => switch (paymentMode) {
        null || '' => null,
        'mobile_money' => 'Mobile money',
        'virement' => 'Virement',
        'espèces' => 'Espèces',
        'cheque' => 'Chèque',
        final other => other,
      };

  String? get periodicityLabel => switch (periodicity) {
        null || '' => null,
        final p => '${p[0].toUpperCase()}${p.substring(1)}',
      };

  factory RentalContract.fromBackend(Map<String, dynamic> j) {
    Map<String, dynamic> obj(String key) =>
        j[key] is Map ? Map<String, dynamic>.from(j[key] as Map) : const {};
    final bien = obj('biens');
    final tenant = obj('locataires');
    final propertyName = (bien['nom'] as String?)?.trim();
    final tenantName = [tenant['prenoms'], tenant['nom']]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    final number = j['numeroContrat'] as String?;
    return RentalContract(
      id: (j['contratsLocationId'] ?? '').toString(),
      title: 'Bail — ${propertyName?.isNotEmpty == true ? propertyName : 'Bien locatif'}',
      status: (j['statut'] ?? '').toString(),
      number: number,
      propertyId: (j['biensId'] ?? bien['biensId'])?.toString(),
      propertyName: propertyName,
      propertyAddress: [bien['adresse'], bien['ville']]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(', '),
      tenantId: (j['locatairesId'] ?? tenant['locatairesId'])?.toString(),
      tenantName: tenantName.isEmpty ? null : tenantName,
      tenantPhone: tenant['telephone'] as String?,
      ownerId: j['utilisateursId']?.toString(),
      rentAmount: _amount(j['loyerMensuel']),
      deposit: _amount(j['caution']),
      agencyFees: _amount(j['fraisAgence']),
      paymentMode: j['modePaiement'] as String?,
      periodicity: j['periodicite'] as String?,
      startDate: _date(j['dateDebut']),
      endDate: _date(j['dateFin']),
      tenantSignedAt: _date(j['dateSignatureLocataire']),
      ownerSignedAt: _date(j['dateSignatureProprietaire']),
      pdfPath: j['urlPdf'] as String?,
      terminationRequested: j['resiliationDemandee'] == true,
      terminationEndOn: _date(j['dateFinDemandee']),
      terminationReason: j['raisonResiliation'] as String?,
      terminationRequestedAt: _date(j['dateDemandeResiliation']),
      terminationApproved: j['approbationProprietaireResiliation'] == true,
      ownerNotes: j['notesProprietaireResiliation'] as String?,
      // Short enough for one line on a phone card
      documentType: number == null ? 'Contrat de location' : 'Contrat n° $number',
    );
  }

  static double? _amount(Object? v) => v == null ? null : double.tryParse('$v');

  static DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');
}
