import 'package:flutter/material.dart';

import 'package:peyapay/src/data/models/transaction.item.dart';
import 'package:peyapay/src/core/utils/formatters.util.dart';

class PeyapayTransactionsScreen extends StatelessWidget {
  const PeyapayTransactionsScreen({super.key, required this.items});
  final List<TransactionItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final iconBgGrey = isDark ? cs.surfaceContainerHighest : const Color(0xFFF3F4F6);

    final title = 'Transactions (${items.length})';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.chevron_left_rounded, size: 26, color: ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      if (items.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Aucune transaction pour le moment',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                          ),
                        )
                      else
                        for (final item in items)
                          GestureDetector(
                            onTap: () => _showTxAlert(context, item),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: iconBgGrey,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(Icons.swap_horiz_rounded, size: 18, color: ink),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.recipient,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formatFrDateOnly(item.dateIso),
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${formatFrMoneySigned(item.amount)} XOF',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showTxAlert(BuildContext context, TransactionItem item) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Transaction'),
      content: Text('${item.recipient}\n${formatFrMoneySigned(item.amount)} XOF'),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
    ),
  );
}

