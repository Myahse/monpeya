class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.recipient,
    required this.dateIso,
    required this.amount,
  });

  final String id;
  final String recipient;
  final String dateIso;
  final int amount;
}

