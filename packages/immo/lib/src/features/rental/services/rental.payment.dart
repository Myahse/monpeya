class RentalPayment {
  const RentalPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.comment,
    this.contractId,
    this.tenantId,
  });

  final String id;
  final double amount;
  final DateTime? paidAt;
  final String? comment;
  final String? contractId;
  final String? tenantId;

  factory RentalPayment.fromBackend(Map<String, dynamic> item) {
    return RentalPayment(
      id: (item['paiementsId'] ?? item['id'] ?? '').toString(),
      amount: double.tryParse('${item['montant']}') ?? 0,
      paidAt: DateTime.tryParse('${item['datePaiement']}'),
      comment: item['commentaire'] as String?,
      contractId: item['contratsLocationId']?.toString(),
      tenantId: item['locatairesId']?.toString(),
    );
  }
}
