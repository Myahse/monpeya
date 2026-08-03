import 'package:flutter/material.dart';

import 'package:peyapay/src/data/models/transaction.item.dart';
import 'package:peyapay/src/data/services/peyapay_transaction_pdf.service.dart';
import 'package:peyapay/src/presentation/widgets/review_transfer_sheet.widget.dart';

TransactionItem peyapayTransactionItemFromTransferReceipt({
  required PeyapayTransactionType type,
  required int amount,
  required PeyapayRecipient recipient,
  String? transactionId,
  required DateTime transactionDate,
}) {
  final txType = switch (type) {
    PeyapayTransactionType.payment => TransactionType.payment,
    PeyapayTransactionType.transfer => TransactionType.transfer,
    PeyapayTransactionType.deposit => TransactionType.deposit,
  };

  final ref = transactionId?.replaceFirst('#', '').trim();
  final id = (ref != null && ref.isNotEmpty)
      ? ref
      : transactionDate.millisecondsSinceEpoch.toString();

  final recipientLabel = recipient.reference?.trim().isNotEmpty == true
      ? '${recipient.name} — ${recipient.reference!.trim()}'
      : recipient.name;

  final signedAmount = switch (type) {
    PeyapayTransactionType.deposit => amount,
    PeyapayTransactionType.payment => -amount,
    PeyapayTransactionType.transfer => -amount,
  };

  return TransactionItem(
    id: id,
    recipient: recipientLabel,
    dateIso: transactionDate.toUtc().toIso8601String(),
    amount: signedAmount,
    type: txType,
    status: TransactionStatus.completed,
    reference: ref,
    description: recipient.name,
  );
}

Future<void> sharePeyapayTransferReceiptPdf(
  BuildContext context, {
  required PeyapayTransactionType type,
  required int amount,
  required PeyapayRecipient recipient,
  String? transactionId,
  required DateTime transactionDate,
}) {
  final item = peyapayTransactionItemFromTransferReceipt(
    type: type,
    amount: amount,
    recipient: recipient,
    transactionId: transactionId,
    transactionDate: transactionDate,
  );
  return sharePeyapayTransactionPdf(context, item);
}

Future<void> sharePeyapayTransactionPdf(BuildContext context, TransactionItem item) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final service = PeyapayTransactionPdfService();
    final bytes = await service.buildSingleReceipt(item);
    if (context.mounted) navigator.pop();
    await service.sharePdf(
      bytes: bytes,
      fileName: service.fileNameForItem(item),
      subject: 'Reçu PeyaPay — ${item.recipient}',
    );
  } catch (e) {
    if (context.mounted) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Impossible de partager le PDF : $e')),
      );
    }
  }
}

Future<void> sharePeyapayTransactionsStatementPdf(
  BuildContext context, {
  required List<TransactionItem> items,
  required String periodLabel,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final service = PeyapayTransactionPdfService();
    final bytes = await service.buildStatement(items: items, periodLabel: periodLabel);
    if (context.mounted) navigator.pop();
    await service.sharePdf(
      bytes: bytes,
      fileName: service.fileNameForStatement(periodLabel),
      subject: 'Relevé PeyaPay — $periodLabel',
    );
  } catch (e) {
    if (context.mounted) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Impossible de partager le PDF : $e')),
      );
    }
  }
}
