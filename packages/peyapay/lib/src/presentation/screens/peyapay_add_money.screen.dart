import 'package:flutter/material.dart';

import 'package:peyapay/src/presentation/widgets/pin_keypad.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_card_brand_badge.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_review_animations.widget.dart';
import 'package:peyapay/src/presentation/widgets/review_transfer_sheet.widget.dart';
import 'package:peyapay/src/presentation/screens/peyapay_review_transfer.screen.dart';

/// Top-up amount after linking a card — same layout as transfer amount entry.
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

class _PeyapayAddMoneyScreenState extends State<PeyapayAddMoneyScreen> with SingleTickerProviderStateMixin {
  static const _fakeBalance = 5000;
  String _digits = '';
  late final List<List<String>> _keypad;

  late final AnimationController _chipAnim;
  late final Animation<Offset> _chipSlide;
  late final Animation<double> _chipFade;
  late final Animation<double> _chipScale;

  @override
  void initState() {
    super.initState();
    _keypad = const [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['0'],
    ];

    _chipAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 580));
    final curve = CurvedAnimation(parent: _chipAnim, curve: Curves.easeOutCubic);
    _chipSlide = Tween<Offset>(begin: const Offset(0, 2.2), end: Offset.zero).animate(curve);
    _chipFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _chipAnim, curve: Curves.easeOut));
    _chipScale = Tween<double>(begin: 0.98, end: 1).animate(CurvedAnimation(parent: _chipAnim, curve: Curves.easeOutBack));
    _chipAnim.forward();
  }

  @override
  void dispose() {
    _chipAnim.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_digits) ?? 0;

  int get _transferFee {
    if (_amount <= 0) return 0;
    return (_amount * 0.005).ceil();
  }

  String get _formattedAmount {
    if (_digits.isEmpty) return '';
    final s = _digits.length > 12 ? _digits.substring(0, 12) : _digits;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  void _onKey(String k) {
    setState(() {
      if (k == 'del') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
        return;
      }
      if (k == 'noop') return;
      if (_digits.length >= 9) return;
      if (k.length == 1 && RegExp(r'^[0-9]$').hasMatch(k)) {
        _digits = _digits + k;
      }
    });
  }

  Future<void> _continueToReview() async {
    if (_amount <= 0) return;

    final ok = await Navigator.of(context).push<bool>(
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

    final canNext = _amount > 0;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
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
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          'Balance: $_fakeBalance frcs',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44, height: 44),
                ],
              ),
            ),
            const SizedBox(height: 120),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formattedAmount.isEmpty ? '0' : _formattedAmount,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: ink, height: 1.0),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('frcs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: muted)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(color: bg),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PinKeypad(
                            keypad: _keypad,
                            onKeyPress: (n) => _onKey(n),
                            onDelete: () => _onKey('del'),
                            onLongDelete: () => setState(() => _digits = ''),
                            textColor: ink,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: canNext ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: !canNext ? null : _continueToReview,
                              child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 50 + 64 + (56 * 4) + (4 * 2),
                    child: ClipRect(
                      child: FadeTransition(
                        opacity: _chipFade,
                        child: SlideTransition(
                          position: _chipSlide,
                          child: ScaleTransition(
                            scale: _chipScale,
                            child: Transform.translate(
                              offset: const Offset(0, 18),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 82),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: border),
                                ),
                                child: Row(
                                  children: [
                                    PeyapayCardBrandBadge(
                                      cardType: widget.cardType,
                                      size: PeyapayCardBrandBadgeSize.row,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dépôt vers Compte principal',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${widget.bankName} • •••• ${widget.cardLastFour}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
