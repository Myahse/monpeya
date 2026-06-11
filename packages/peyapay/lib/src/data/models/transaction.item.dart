enum TransactionType { transfer, deposit, payment, withdrawal }

enum TransactionStatus { completed, pending, failed }

class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.recipient,
    required this.dateIso,
    required this.amount,
    this.type = TransactionType.transfer,
    this.status = TransactionStatus.completed,
    this.reference,
    this.description,
  });

  final String id;
  final String recipient;
  final String dateIso;
  final int amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? reference;
  final String? description;

  bool get isCredit => amount > 0;

  String get typeLabel => switch (type) {
        TransactionType.transfer => 'Transfert',
        TransactionType.deposit => 'Dépôt',
        TransactionType.payment => 'Paiement',
        TransactionType.withdrawal => 'Retrait',
      };

  String get statusLabel => switch (status) {
        TransactionStatus.completed => 'Complétée',
        TransactionStatus.pending => 'En cours',
        TransactionStatus.failed => 'Échouée',
      };
}
