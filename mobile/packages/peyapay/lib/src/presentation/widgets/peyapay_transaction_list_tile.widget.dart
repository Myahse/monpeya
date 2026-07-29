import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/data/models/transaction.item.dart';

class PeyapayTransactionListTile extends StatelessWidget {
  const PeyapayTransactionListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.ink,
    this.muted,
    this.border,
    this.iconBg,
    this.surface,
  });

  final TransactionItem item;
  final VoidCallback onTap;
  final Color? ink;
  final Color? muted;
  final Color? border;
  final Color? iconBg;
  final Color? surface;

  IconData _iconForType() => switch (item.type) {
        TransactionType.deposit => Icons.south_west_rounded,
        TransactionType.withdrawal => Icons.north_east_rounded,
        TransactionType.payment => Icons.storefront_outlined,
        TransactionType.transfer => Icons.swap_horiz_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = ink ?? (isDark ? cs.onSurface : const Color(0xFF111827));
    final mutedColor = muted ?? (isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280));
    final borderColor = border ?? (isDark ? cs.outlineVariant : const Color(0xFFE5E7EB));
    final iconBgColor = iconBg ?? (isDark ? cs.surfaceContainerHighest : const Color(0xFFF3F4F6));
    final surfaceColor = surface ?? (isDark ? cs.surface : const Color(0xFFFFFFFF));
    final amountColor = item.isCredit ? const Color(0xFF006D56) : inkColor;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(_iconForType(), size: 20, color: inkColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.recipient,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: inkColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.typeLabel} • ${formatFrDateOnly(item.dateIso)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.isCredit ? '+' : '-'}${formatFrMoneySigned(item.amount.abs())} XOF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: amountColor),
                  ),
                  if (item.status != TransactionStatus.completed) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: item.status == TransactionStatus.failed
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: mutedColor),
            ],
          ),
        ),
      ),
    );
  }
}
