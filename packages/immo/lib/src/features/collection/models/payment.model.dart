/// One rent instalment — scheduled (`dueDate`) and, once collected, `paidAt`.
class CollectionPayment {
  const CollectionPayment({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    this.status,
    this.tenantId,
    this.tenantName,
    this.propertyId,
    this.propertyName,
    this.method,
    this.reference,
  });

  final String id;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? status;
  final String? tenantId;
  final String? tenantName;
  final String? propertyId;
  final String? propertyName;
  final String? method;
  final String? reference;

  bool get isPaid => status == 'paid' || (status == null && paidAt != null);

  bool isLate(DateTime now) => !isPaid && dueDate.isBefore(now);

  factory CollectionPayment.fromBackend(Map<String, dynamic> item) {
    final paidAt = DateTime.tryParse('${item['datePaiement']}');
    return CollectionPayment(
      id: (item['paiementsId'] ?? '').toString(),
      amount: double.tryParse('${item['montant']}') ?? 0,
      // A one-off payment has no due date: it was due when it was paid.
      dueDate: DateTime.tryParse('${item['dateEcheance']}') ??
          paidAt ??
          DateTime.now(),
      paidAt: paidAt,
      status: item['statut'] as String?,
      tenantId: item['locatairesId']?.toString(),
      tenantName: item['locataireNom'] as String?,
      propertyId: item['biensId']?.toString(),
      propertyName: item['bienNom'] as String?,
      method: item['methodePaiement'] as String?,
      reference: item['reference'] as String?,
    );
  }
}
