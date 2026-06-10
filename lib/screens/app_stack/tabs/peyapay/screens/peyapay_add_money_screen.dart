import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../widgets/peyapay_card_brand_badge.dart';
import '../widgets/peyapay_review_animations.dart';
import '../widgets/review_transfer_sheet.dart';
import 'peyapay_review_transfer_screen.dart';

/// Top-up amount after linking a card — RN `AddMoney` → `ReviewTransfer` (deposit).
class PeyapayAddMoneyScreen extends StatefulWidget {
  const PeyapayAddMoneyScreen({
    super.key,
    this.cardType = 'VISA',
    this.bankName = 'Société générale',
    this.cardLastFour = '4387',
    this.onDepositComplete,
  });

  final String cardType;
  final String bankName;
  final String cardLastFour;
  final VoidCallback? onDepositComplete;

  @override
  State<PeyapayAddMoneyScreen> createState() => _PeyapayAddMoneyScreenState();
}

class _PeyapayAddMoneyScreenState extends State<PeyapayAddMoneyScreen> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  static String _formatMoney(String input) {
    final d = _digitsOnly(input);
    if (d.isEmpty) return '';
    final s = d.length > 12 ? d.substring(0, 12) : d;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  int get _amount => int.tryParse(_digitsOnly(_amountCtrl.text)) ?? 0;

  int get _transferFee {
    if (_amount <= 0) return 0;
    return (_amount * 0.005).ceil();
  }

  void _setAmount(int value) {
    final next = _formatMoney(value.toString());
    _amountCtrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() {});
  }

  Future<void> _continueToReview() async {
    if (_amount <= 0) return;

    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      peyapayReviewTransferRoute(
        PeyapayReviewTransferScreen(
          type: PeyapayTransactionType.deposit,
          amount: _amount,
          fee: _transferFee,
          onDepositComplete: widget.onDepositComplete,
          sender: PeyapaySender(
            title: widget.bankName,
            subtitle: '${widget.cardType.toLowerCase()} debit • ${widget.cardLastFour}',
            icon: Icons.credit_card,
          ),
          recipient: const PeyapayRecipient(
            name: 'Compte principal',
            reference: 'Sparrowhawk • 02238762',
            icon: Icons.account_balance_wallet_outlined,
            color: Color(0xFF006D56),
          ),
        ),
      ),
    );

    if (!mounted || ok != true) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

    final displayAmount = _amountCtrl.text.isEmpty ? '0' : _amountCtrl.text;
    final canContinue = _amount > 0;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.chevron_left, size: 26, color: ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Input amount',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          displayAmount,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: _amountCtrl.text.isEmpty ? muted.withValues(alpha: 0.5) : ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('frcs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: muted)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                              decoration: InputDecoration(
                                hintText: 'Saisir un montant',
                                hintStyle: TextStyle(color: muted, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (v) {
                                final next = _formatMoney(v);
                                if (next != _amountCtrl.text) {
                                  _amountCtrl.value = TextEditingValue(
                                    text: next,
                                    selection: TextSelection.collapsed(offset: next.length),
                                  );
                                }
                                setState(() {});
                              },
                            ),
                          ),
                          Text('XOF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: muted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _AmountChip(label: '5 000', onTap: () => _setAmount(5000)),
                        _AmountChip(label: '10 000', onTap: () => _setAmount(10000)),
                        _AmountChip(label: '25 000', onTap: () => _setAmount(25000)),
                        _AmountChip(label: '50 000', onTap: () => _setAmount(50000)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          PeyapayCardBrandBadge(
                            cardType: widget.cardType,
                            size: PeyapayCardBrandBadgeSize.row,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.bankName,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.cardType.toLowerCase()} debit',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '•••• ${widget.cardLastFour}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Résumé', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
                          const SizedBox(height: 10),
                          _kv('Destination', 'Compte principal', ink, muted),
                          const SizedBox(height: 8),
                          _kv('Montant', '${formatFrMoneySigned(_amount)} XOF', ink, muted),
                          if (_amount > 0) ...[
                            const SizedBox(height: 8),
                            _kv('Frais (0,5 %)', '${formatFrMoneySigned(_transferFee)} XOF', ink, muted),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 0),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: canContinue ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: canContinue ? _continueToReview : null,
                    child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink)),
      ),
    );
  }
}

Widget _kv(String k, String v, Color ink, Color muted) {
  return Row(
    children: [
      Expanded(child: Text(k, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted))),
      const SizedBox(width: 12),
      Flexible(
        child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink)),
      ),
    ],
  );
}
