import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_party_cards_stack.widget.dart';
import 'package:peyapay/src/presentation/screens/peyapay_payment_success.screen.dart';

class PeyapayPaymentReviewScreen extends StatefulWidget {
  const PeyapayPaymentReviewScreen({
    super.key,
    required this.merchantName,
    required this.amount,
    this.merchantIcon,
    this.merchantColor,
  });

  final String merchantName;
  final int amount;
  final IconData? merchantIcon;
  final Color? merchantColor;

  @override
  State<PeyapayPaymentReviewScreen> createState() => _PeyapayPaymentReviewScreenState();
}

class _PeyapayPaymentReviewScreenState extends State<PeyapayPaymentReviewScreen> {
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PeyapayPaymentSuccessScreen(
          title: 'Paiement confirmé',
          subtitle: 'Votre paiement a été effectué avec succès.',
          amount: widget.amount,
          merchantName: widget.merchantName,
          merchantIcon: widget.merchantIcon,
          merchantColor: widget.merchantColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

    const green = Color(0xFF006D56);

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
                  Text('Vérification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PeyapayPartyCardsStack(
                        left: const PeyapayPartyCardData(
                          title: 'Compte principal',
                          subtitle: 'Sparrowhawk • 02238762',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        right: PeyapayPartyCardData(
                          title: widget.merchantName,
                          subtitle: 'Paiement',
                          icon: widget.merchantIcon ?? Icons.storefront_outlined,
                          iconColor: widget.merchantColor,
                        ),
                        ink: ink,
                        muted: muted,
                        cardBg: bg,
                        cutoutBg: bg,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Récapitulatif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
                            const SizedBox(height: 12),
                            _row('Montant', '${formatFrMoneySigned(widget.amount)} XOF', ink, muted),
                            const SizedBox(height: 10),
                            _row('Frais', '0 XOF', ink, muted),
                            const SizedBox(height: 10),
                            const Divider(height: 18),
                            _row(
                              'Total',
                              '${formatFrMoneySigned(widget.amount)} XOF',
                              ink,
                              muted,
                              valueStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18, color: muted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Confirmez pour effectuer le paiement.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _submitting ? null : _confirm,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w900)),
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

Widget _row(
  String k,
  String v,
  Color ink,
  Color muted, {
  TextStyle? valueStyle,
}) {
  return Row(
    children: [
      Expanded(child: Text(k, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted))),
      const SizedBox(width: 12),
      Text(v, style: valueStyle ?? TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink)),
    ],
  );
}

