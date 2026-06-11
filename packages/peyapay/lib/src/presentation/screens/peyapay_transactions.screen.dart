import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/core/utils/screen_insets.util.dart';
import 'package:peyapay/src/data/models/transaction.item.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transaction_detail.screen.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transaction_list_tile.widget.dart';

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

    final sections = _groupByDate(items);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, peyapayStatusBarTop(context), 16, 12),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.chevron_left_rounded, color: ink, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Expanded(
                    child: Text(
                      'Transactions',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _TransactionsSummary(items: items, ink: ink, muted: muted, border: border, surface: bg),
            ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucune transaction pour le moment',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: muted),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 10, top: index == 0 ? 0 : 8),
                            child: Text(
                              section.label,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: muted),
                            ),
                          ),
                          for (final item in section.items) ...[
                            PeyapayTransactionListTile(
                              item: item,
                              ink: ink,
                              muted: muted,
                              border: border,
                              iconBg: iconBgGrey,
                              surface: bg,
                              onTap: () => openPeyapayTransactionDetail(context, item),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsSummary extends StatelessWidget {
  const _TransactionsSummary({
    required this.items,
    required this.ink,
    required this.muted,
    required this.border,
    required this.surface,
  });

  final List<TransactionItem> items;
  final Color ink;
  final Color muted;
  final Color border;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final credits = items.where((t) => t.isCredit).fold<int>(0, (sum, t) => sum + t.amount);
    final debits = items.where((t) => !t.isCredit).fold<int>(0, (sum, t) => sum + t.amount.abs());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryCell('Entrées', '+${formatFrMoneySigned(credits)}', const Color(0xFF006D56), muted),
          ),
          Container(width: 1, height: 36, color: border),
          Expanded(
            child: _summaryCell('Sorties', '-${formatFrMoneySigned(debits)}', ink, muted),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value, Color valueColor, Color mutedColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedColor)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}

class _TransactionSection {
  const _TransactionSection({required this.label, required this.items});

  final String label;
  final List<TransactionItem> items;
}

List<_TransactionSection> _groupByDate(List<TransactionItem> items) {
  final sorted = [...items]..sort((a, b) => b.dateIso.compareTo(a.dateIso));
  final map = <String, List<TransactionItem>>{};

  for (final item in sorted) {
    final label = formatFrDateSectionLabel(item.dateIso);
    map.putIfAbsent(label, () => []).add(item);
  }

  return [
    for (final entry in map.entries) _TransactionSection(label: entry.key, items: entry.value),
  ];
}
