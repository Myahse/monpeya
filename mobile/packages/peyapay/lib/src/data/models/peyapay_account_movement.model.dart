import 'package:peyapay/src/data/models/transaction.item.dart';

class PeyapayAccountMovementsPage {
  const PeyapayAccountMovementsPage({
    required this.movements,
    this.totalCount,
  });

  final List<PeyapayAccountMovement> movements;
  final int? totalCount;
}

class PeyapayAccountMovement {
  const PeyapayAccountMovement({
    this.dateOperation,
    this.dateOperationSort,
    this.codeoperation,
    this.codeoperationbq,
    this.numOperation,
    required this.montant,
    this.refrel,
    this.numerocomptecomplet,
    this.libelle,
    this.heureOp,
  });

  final String? dateOperation;
  final String? dateOperationSort;
  final String? codeoperation;
  final String? codeoperationbq;
  final String? numOperation;
  final int montant;
  final String? refrel;
  final String? numerocomptecomplet;
  final String? libelle;
  final String? heureOp;

  factory PeyapayAccountMovement.fromJson(Map<String, dynamic> json) {
    return PeyapayAccountMovement(
      dateOperation: json['dateOperation']?.toString(),
      dateOperationSort: json['dateOperationSort']?.toString(),
      codeoperation: json['codeoperation']?.toString(),
      codeoperationbq: json['codeoperationbq']?.toString(),
      numOperation: json['numOperation']?.toString(),
      montant: _parseMontant(json['montant']),
      refrel: json['refrel']?.toString(),
      numerocomptecomplet: json['numerocomptecomplet']?.toString(),
      libelle: json['libelle']?.toString(),
      heureOp: json['heureOp']?.toString(),
    );
  }

  TransactionItem toTransactionItem() {
    return TransactionItem(
      id: numOperation?.trim().isNotEmpty == true ? numOperation! : _fallbackId(),
      recipient: _recipientLabel(),
      dateIso: _resolveDateIso(),
      amount: montant,
      type: _resolveType(),
      reference: numOperation,
      description: libelle?.trim(),
    );
  }

  String _fallbackId() {
    final parts = [dateOperation, codeoperation, montant.toString(), libelle];
    return parts.whereType<String>().where((p) => p.isNotEmpty).join('-');
  }

  String _recipientLabel() {
    final label = libelle?.trim();
    if (label != null && label.isNotEmpty) return label;
    return switch (_resolveType()) {
      TransactionType.withdrawal => 'Retrait',
      TransactionType.payment => 'Paiement',
      TransactionType.deposit => 'Dépôt',
      TransactionType.transfer => 'Transfert',
    };
  }

  String _resolveDateIso() {
    final sorted = dateOperationSort?.trim();
    if (sorted != null && sorted.isNotEmpty) {
      final parsed = DateTime.tryParse(sorted);
      if (parsed != null) return parsed.toUtc().toIso8601String();
    }

    final op = dateOperation?.trim();
    if (op != null && op.isNotEmpty) {
      final parts = op.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime.utc(year, month, day).toIso8601String();
        }
      }
    }

    return DateTime.now().toUtc().toIso8601String();
  }

  TransactionType _resolveType() {
    final code = '${codeoperation ?? ''}${codeoperationbq ?? ''}'.toUpperCase();
    if (code.contains('RET')) return TransactionType.withdrawal;
    if (code.contains('PAY')) return TransactionType.payment;
    if (montant > 0 && code.contains('DEP')) return TransactionType.deposit;
    return TransactionType.transfer;
  }

  static int _parseMontant(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
