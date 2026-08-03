import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/core/utils/screen_insets.util.dart';
import 'package:peyapay/src/core/utils/peyapay_transaction_share.util.dart';
import 'package:peyapay/src/data/models/transaction.item.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_amount_with_cfa.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_nav_bar_icon.widget.dart';

class PeyapayTransactionDetailScreen extends StatelessWidget {
  const PeyapayTransactionDetailScreen({super.key, required this.item});

  final TransactionItem item;

  static const _green = Color(0xFF006D56);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final amountColor = item.isCredit ? _green : ink;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, peyapayStatusBarTop(context) + 16, 16, 12),
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
                      'Détail transaction',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () => sharePeyapayTransactionPdf(context, item),
                    icon: Icon(Icons.ios_share_rounded, color: ink, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    tooltip: 'Partager en PDF',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const PeyaPayNavBarIcon(size: 44, width: 120),
                  const SizedBox(height: 20),
                  PeyapayAmountWithCfa(
                    amount: item.amount,
                    color: amountColor,
                    showSign: true,
                    isCredit: item.isCredit,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Type', value: item.typeLabel, ink: ink, muted: muted),
                        _divider(border),
                        _DetailRow(label: 'Date', value: formatFrDateTime(item.dateIso), ink: ink, muted: muted),
                        _divider(border),
                        _DetailRow(label: 'Statut', value: item.statusLabel, ink: ink, muted: muted),
                        if (item.reference != null && item.reference!.isNotEmpty) ...[
                          _divider(border),
                          _DetailRow(label: 'Référence', value: item.reference!, ink: ink, muted: muted, mono: true),
                        ],
                        if (item.description != null && item.description!.isNotEmpty) ...[
                          _divider(border),
                          _DetailRow(label: 'Libellé', value: item.description!, ink: ink, muted: muted),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => sharePeyapayTransactionPdf(context, item),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Partager le reçu PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: item.reference == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: item.reference!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Référence copiée')),
                              );
                            },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copier la référence'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(color: _green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: color),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.ink,
    required this.muted,
    this.mono = false,
  });

  final String label;
  final String value;
  final Color ink;
  final Color muted;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ink,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

void openPeyapayTransactionDetail(BuildContext context, TransactionItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PeyapayTransactionDetailScreen(item: item),
    ),
  );
}
