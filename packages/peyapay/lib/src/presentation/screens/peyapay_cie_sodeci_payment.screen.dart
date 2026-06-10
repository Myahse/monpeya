import 'dart:math';

import 'package:flutter/material.dart';

import 'package:peyapay/src/core/constants/peya_pay.assets.dart';
import 'package:peyapay/src/core/utils/peyapay_session.util.dart';

import 'package:peyapay/src/presentation/widgets/peyapay_review_animations.widget.dart';
import 'package:peyapay/src/presentation/widgets/review_transfer_sheet.widget.dart';
import 'package:peyapay/src/presentation/screens/peyapay_review_transfer.screen.dart';

enum PeyapayBillServiceType { cie, sodeci }

class PeyapayCieSodeciPaymentScreen extends StatefulWidget {
  const PeyapayCieSodeciPaymentScreen({
    super.key,
    required this.serviceType,
    this.onClose,
  });

  final PeyapayBillServiceType serviceType;
  final VoidCallback? onClose;

  @override
  State<PeyapayCieSodeciPaymentScreen> createState() => _PeyapayCieSodeciPaymentScreenState();
}

class _PeyapayCieSodeciPaymentScreenState extends State<PeyapayCieSodeciPaymentScreen> {
  final _referenceCtrl = TextEditingController();

  bool _searching = false;
  bool _showBill = false;

  String _billNumber = '';
  String _period = '';
  String _paymentLimit = '';
  int _amount = 0;

  String _paymentMode = 'total'; // total | partial
  _PaymentMethod _method = _PaymentMethod.mainAccount;

  @override
  void dispose() {
    _referenceCtrl.dispose();
    super.dispose();
  }

  String get _serviceName => widget.serviceType == PeyapayBillServiceType.cie ? 'CIE' : 'SODECI';
  String get _recipientName =>
      widget.serviceType == PeyapayBillServiceType.cie ? 'CIE - Electricity Bill' : 'SODECI - Water Bill';

  String? get _logoAsset => widget.serviceType == PeyapayBillServiceType.cie
      ? 'assets/logo/logo_partenaires.png'
      : 'assets/logo/logo_sodeci.png';

  Color get _accent => widget.serviceType == PeyapayBillServiceType.cie ? const Color(0xFFFF6B35) : const Color(0xFF0066CC);

  void _back() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  bool get _referenceOk => _referenceCtrl.text.trim().length == 9;

  Future<void> _searchBill() async {
    if (_searching || !_referenceOk) return;
    setState(() => _searching = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Demo bill response (matches NTERI behavior).
    setState(() {
      _searching = false;
      _showBill = true;
      _billNumber = '027845637382904635';
      _period = 'March 2025';
      _paymentLimit = 'June 10 2025';
      _amount = 100000;
    });
  }

  Future<void> _pickMethod() async {
    final chosen = await showModalBottomSheet<_PaymentMethod>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: isDark ? Colors.white : border, width: 0.5),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(height: 14),
                    Text('Mode de paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.onSurface)),
                    const SizedBox(height: 14),
                    _MethodTile(
                      title: 'Compte principal',
                      subtitle: 'Sparrowhawk • 02238762',
                      icon: Icons.account_balance_wallet_outlined,
                      selected: _method == _PaymentMethod.mainAccount,
                      onTap: () => Navigator.of(context).pop(_PaymentMethod.mainAccount),
                    ),
                    const SizedBox(height: 10),
                    _MethodTile(
                      title: 'Carte bancaire',
                      subtitle: 'VISA • 4387',
                      icon: Icons.credit_card,
                      selected: _method == _PaymentMethod.visaCard,
                      onTap: () => Navigator.of(context).pop(_PaymentMethod.visaCard),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (chosen == null) return;
    setState(() => _method = chosen);
  }

  Future<void> _pay() async {
    if (!_showBill) return;

    final allowed = await peyapayEnsureRegisteredForTransaction(context);
    if (!mounted || !allowed) return;

    final fee = max(0, (_amount * 0.005).ceil());
    final ok = await Navigator.of(context).push<bool>(
      peyapayReviewTransferRoute(
        PeyapayReviewTransferScreen(
          type: PeyapayTransactionType.payment,
          amount: _amount,
          fee: fee,
          sender: _method == _PaymentMethod.mainAccount
              ? const PeyapaySender(
                  title: 'Compte principal',
                  subtitle: 'Sparrowhawk • 02238762',
                  icon: Icons.account_balance_wallet_outlined,
                )
              : const PeyapaySender(
                  title: 'Carte bancaire',
                  subtitle: 'VISA • 4387',
                  icon: Icons.credit_card,
                ),
          recipient: PeyapayRecipient(
            name: _recipientName,
            reference: _billNumber,
            icon: widget.serviceType == PeyapayBillServiceType.cie ? Icons.lightbulb_outline : Icons.water_drop_outlined,
            color: _accent,
          ),
        ),
      ),
    );
    if (!mounted || ok != true) return;
    // success + receipt are handled in review
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

    final canSearch = _referenceOk && !_searching;
    final canPay = _showBill;

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
                    onTap: _back,
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
                  Text(_serviceName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
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
                      Center(
                        child: SizedBox(
                          height: 62,
                          child: _logoAsset == null
                              ? const SizedBox()
                              : Image.asset(
      _logoAsset!,
      package: PeyaPayAssets.package,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Saisissez votre référence',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Les 9 premiers chiffres sur votre facture.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: TextField(
                          controller: _referenceCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 9,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Ex: 123456789',
                            hintStyle: TextStyle(color: muted),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: canSearch ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: canSearch ? _searchBill : null,
                          child: _searching
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Rechercher', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      if (_showBill) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            children: [
                              _kv('Facture #', _billNumber, ink, muted),
                              const SizedBox(height: 10),
                              _kv('Période', _period, ink, muted),
                              const SizedBox(height: 10),
                              _kv('Date limite', _paymentLimit, ink, muted),
                              const Divider(height: 18),
                              _kv('Total', '$_amount XOF', ink, muted),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeChip(
                                label: 'Total',
                                active: _paymentMode == 'total',
                                onTap: () => setState(() => _paymentMode = 'total'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ModeChip(
                                label: 'Partiel',
                                active: _paymentMode == 'partial',
                                onTap: () => setState(() => _paymentMode = 'partial'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickMethod,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Icon(_method == _PaymentMethod.mainAccount ? Icons.account_balance_wallet_outlined : Icons.credit_card, color: ink, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _method == _PaymentMethod.mainAccount ? 'Compte principal' : 'Carte bancaire',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _method == _PaymentMethod.mainAccount ? 'Sparrowhawk • 02238762' : 'VISA • 4387',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: muted),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                      backgroundColor: canPay ? const Color(0xFF006D56) : const Color(0xFFB9D8CF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: canPay ? _pay : null,
                    child: const Text('Payer', style: TextStyle(fontWeight: FontWeight.w900)),
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

enum _PaymentMethod { mainAccount, visaCard }

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
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
        height: 42,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF006D56) : (isDark ? cs.surfaceContainerHighest : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : ink,
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFF006D56) : border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: ink, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF006D56), size: 18),
          ],
        ),
      ),
    );
  }
}

Widget _kv(String k, String v, Color ink, Color muted) {
  return Row(
    children: [
      Expanded(child: Text(k, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted))),
      const SizedBox(width: 12),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink))),
    ],
  );
}

