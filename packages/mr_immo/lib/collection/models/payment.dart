class CollectionPayment {
  const CollectionPayment({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.paidAt,
  });

  final String id;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
}
