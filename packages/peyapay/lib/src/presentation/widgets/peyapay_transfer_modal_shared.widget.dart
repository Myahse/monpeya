import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/presentation/widgets/review_transfer_sheet.widget.dart';
class PeyapayTransferStatusPill extends StatelessWidget {
  const PeyapayTransferStatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF006D56);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PeyapayTransferDetailRow extends StatelessWidget {
  const PeyapayTransferDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.ink,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color ink;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: ink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: valueColor ?? ink,
            ),
          ),
        ),
      ],
    );
  }
}

String peyapayTransferFeePercentLabel(int amount, int fee) {
  if (amount <= 0 || fee <= 0) return '0';
  final pct = (fee / amount) * 100;
  if (pct == pct.roundToDouble()) return pct.toStringAsFixed(0);
  return pct.toStringAsFixed(1);
}

String peyapayTransferEnglishDate(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String peyapayTransferStatusLabel(PeyapayTransactionType type) => switch (type) {
      PeyapayTransactionType.payment => 'Paiement réussi',
      PeyapayTransactionType.transfer => 'Débit effectué',
      PeyapayTransactionType.deposit => 'Dépôt réussi',
    };

String peyapayTransferCategoryLabel(PeyapayTransactionType type) => switch (type) {
      PeyapayTransactionType.payment => 'Paiement',
      PeyapayTransactionType.transfer => 'Transfert',
      PeyapayTransactionType.deposit => 'Dépôt',
    };

class PeyapayTransferResultPanel extends StatelessWidget {
  const PeyapayTransferResultPanel({
    super.key,
    required this.amount,
    required this.fee,
    required this.type,
    required this.recipient,
    required this.recipientRef,
    required this.senderTitle,
    required this.senderSubtitle,
    required this.txId,
    required this.txDate,
    required this.categoryLabel,
    required this.ink,
    required this.muted,
    required this.border,
    required this.green,
  });

  final int amount;
  final int fee;
  final PeyapayTransactionType type;
  final PeyapayRecipient recipient;
  final String recipientRef;
  final String senderTitle;
  final String senderSubtitle;
  final String txId;
  final String txDate;
  final String categoryLabel;
  final Color ink;
  final Color muted;
  final Color border;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
      children: [
        Text(
          '+${formatFrMoneySigned(amount)} frcs',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: ink,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Vers ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: muted),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: (recipient.color ?? green).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                recipient.icon ?? Icons.person_outline,
                size: 14,
                color: recipient.color ?? green,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${recipient.name} - $recipientRef',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PeyapayTransferDetailRow(
          icon: Icons.account_balance_wallet_outlined,
          label: 'De',
          value: '$senderTitle | $senderSubtitle',
          ink: ink,
        ),
        const SizedBox(height: 14),
        PeyapayTransferDetailRow(
          icon: Icons.payments_outlined,
          label: type == PeyapayTransactionType.deposit ? 'Montant ajouté' : 'Montant',
          value: '${formatFrMoneySigned(amount)} frcs',
          ink: ink,
        ),
        const SizedBox(height: 14),
        PeyapayTransferDetailRow(
          icon: Icons.receipt_long_outlined,
          label: fee > 0
              ? 'Frais de transfert (${peyapayTransferFeePercentLabel(amount, fee)}%)'
              : 'Frais de transfert',
          value: fee == 0 ? 'Gratuit' : '${formatFrMoneySigned(fee)} frcs',
          ink: ink,
          valueColor: fee == 0 ? green : ink,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(height: 1, color: border.withValues(alpha: 0.7)),
        ),
        PeyapayTransferDetailRow(
          icon: Icons.swap_horiz_rounded,
          label: 'ID transaction',
          value: txId,
          ink: ink,
        ),
        const SizedBox(height: 14),
        PeyapayTransferDetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date de transaction',
          value: txDate,
          ink: ink,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.grid_view_rounded, size: 20, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Catégorie',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == PeyapayTransactionType.deposit
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 14,
                    color: green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    categoryLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
