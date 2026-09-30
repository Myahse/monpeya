class SimConfirmPaymentRequest {
  const SimConfirmPaymentRequest({
    required this.referencePaiement,
    required this.montantPercu,
    this.datePaiement,
  });

  final String referencePaiement;
  final int montantPercu;
  final String? datePaiement;

  Map<String, dynamic> toJson() => {
        'referencePaiement': referencePaiement,
        'montantPercu': montantPercu,
        if (datePaiement != null) 'datePaiement': datePaiement,
      };
}

class SimConfirmPaymentResult {
  const SimConfirmPaymentResult({
    required this.id,
    required this.statut,
    this.numeroPolice,
    this.dateDebut,
    this.dateFin,
    this.montantAReverser,
  });

  final String id;
  final String statut;
  final String? numeroPolice;
  final String? dateDebut;
  final String? dateFin;
  final int? montantAReverser;

  factory SimConfirmPaymentResult.fromJson(Map<String, dynamic> json) {
    return SimConfirmPaymentResult(
      id: json['id']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      numeroPolice: json['numeroPolice']?.toString(),
      dateDebut: json['dateDebut']?.toString(),
      dateFin: json['dateFin']?.toString(),
      montantAReverser: (json['montantAReverser'] as num?)?.toInt(),
    );
  }
}
