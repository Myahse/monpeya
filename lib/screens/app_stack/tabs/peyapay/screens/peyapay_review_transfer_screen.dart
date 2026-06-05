import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../widgets/review_transfer_sheet.dart' show PeyapayRecipient, PeyapaySender, PeyapayTransactionType;
import '../widgets/peyapay_party_cards_stack.dart';

class PeyapayReviewTransferScreen extends StatefulWidget {
  const PeyapayReviewTransferScreen({
    super.key,
    required this.type,
    required this.amount,
    required this.fee,
    required this.recipient,
    this.sender,
    this.onDepositComplete,
  });

  final PeyapayTransactionType type;
  final int amount;
  final int fee;
  final PeyapayRecipient recipient;
  final PeyapaySender? sender;
  final VoidCallback? onDepositComplete;

  @override
  State<PeyapayReviewTransferScreen> createState() => _PeyapayReviewTransferScreenState();
}

class _PeyapayReviewTransferScreenState extends State<PeyapayReviewTransferScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _successShown = false;
  bool _leaving = false;

  late final AnimationController _anim;
  late final Animation<Offset> _leftSlide;
  late final Animation<Offset> _rightSlide;
  late final Animation<double> _arrowFade;
  late final Animation<double> _circleScale;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _sheetFade;
  late final Animation<double> _sheetScale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));

    final cardsCurve = CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.62, curve: Curves.easeOutCubic));
    _leftSlide = Tween<Offset>(begin: const Offset(-0.75, 0), end: Offset.zero).animate(cardsCurve);
    _rightSlide = Tween<Offset>(begin: const Offset(0.75, 0), end: Offset.zero).animate(cardsCurve);

    _arrowFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.22, 0.85, curve: Curves.easeOut)),
    );
    _circleScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.1, 0.85, curve: Curves.elasticOut)),
    );

    // Bottom sheet: come from bottom (more distance) + pop
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 0.9), end: Offset.zero).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.62, 1.0, curve: Curves.easeOutQuart)),
    );
    _sheetFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.62, 0.95, curve: Curves.easeOut)),
    );
    _sheetScale = Tween<double>(begin: 0.985, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.62, 1.0, curve: Curves.easeOutCubic)),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
        PeyapayTransactionType.payment => 'Vérification',
        PeyapayTransactionType.transfer => 'Vérification',
        PeyapayTransactionType.deposit => 'Vérification',
      };

  String get _badge => switch (widget.type) {
        PeyapayTransactionType.payment => 'Paiement',
        PeyapayTransactionType.transfer => 'Transfert',
        PeyapayTransactionType.deposit => 'Dépôt',
      };

  Future<void> _confirm() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _loading = false);
    if (_successShown) return;
    _successShown = true;
    await _showSuccessAndReceipt();
    if (!mounted) return;
    if (widget.type == PeyapayTransactionType.deposit) {
      widget.onDepositComplete?.call();
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _showSuccessAndReceipt() async {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    const green = Color(0xFF006D56);

    final title = switch (widget.type) {
      PeyapayTransactionType.payment => 'Paiement confirmé',
      PeyapayTransactionType.transfer => 'Transfert confirmé',
      PeyapayTransactionType.deposit => 'Dépôt confirmé',
    };

    final subtitle = switch (widget.type) {
      PeyapayTransactionType.payment => 'Votre paiement a été effectué avec succès.',
      PeyapayTransactionType.transfer => 'Votre transfert a été effectué avec succès.',
      PeyapayTransactionType.deposit => 'Votre dépôt a été effectué avec succès.',
    };

    final leftTitle = widget.sender?.title ?? 'Compte principal';
    final leftSubtitle = widget.sender?.subtitle ?? 'Sparrowhawk • 02238762';
    final rightTitle = widget.recipient.name;
    final rightSubtitle = widget.recipient.reference?.trim().isNotEmpty == true
        ? widget.recipient.reference!.trim()
        : switch (widget.type) {
            PeyapayTransactionType.payment => 'Paiement',
            PeyapayTransactionType.transfer => 'Transfert',
            PeyapayTransactionType.deposit => 'Dépôt',
          };

    Future<void> showReceipt() async {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reçu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
                  const SizedBox(height: 12),
                  _receiptRow('Type', title, ink, muted),
                  const SizedBox(height: 10),
                  _receiptRow('De', '$leftTitle • $leftSubtitle', ink, muted),
                  const SizedBox(height: 10),
                  _receiptRow('À', '$rightTitle • $rightSubtitle', ink, muted),
                  const SizedBox(height: 10),
                  _receiptRow('Montant', '${formatFrMoneySigned(widget.amount)} XOF', ink, muted),
                  const SizedBox(height: 10),
                  _receiptRow('Frais', '${formatFrMoneySigned(widget.fee)} XOF', ink, muted),
                  const Divider(height: 22),
                  _receiptRow(
                    'Total',
                    '${formatFrMoneySigned(widget.amount + widget.fee)} XOF',
                    ink,
                    muted,
                    valueStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_rounded, color: green, size: 30),
                ),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async => showReceipt(),
                    child: Text('Voir le reçu', style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // After modal is closed, return user to previous flow.
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _leave([bool? result]) async {
    if (_leaving) return;
    _leaving = true;
    try {
      if (_anim.isAnimating) {
        // let current forward finish quickly before reversing
        await _anim.forward();
      }
      await _anim.reverse();
    } finally {
      if (!mounted) return;
      Navigator.of(context).pop(result);
    }
  }

  // Note: screen now matches RN layout; details are inline in bottom container.

  String _formatDateTimeEn(DateTime d) {
    final months = const [
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
    final month = months[d.month - 1];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '$month ${d.day}, ${d.year} $hour12:$mm $ampm';
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
    final total = widget.amount + widget.fee;
    final now = DateTime.now();
    final arrivedAt = _formatDateTimeEn(now);
    final rightSubtitle = widget.recipient.reference?.trim().isNotEmpty == true
        ? widget.recipient.reference!.trim()
        : _badge;

    final leftTitle = widget.sender?.title ?? 'Compte principal';
    final leftSubtitle = widget.sender?.subtitle ?? 'Sparrowhawk • 02238762';
    final rightTitle = widget.recipient.name;

    final topBg = isDark ? cs.surface : const Color(0xFFEBEBEB);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leave(false);
      },
      child: Scaffold(
        backgroundColor: topBg,
        body: SafeArea(
          child: Stack(
          children: [
            // Grey top area (like RN)
            Positioned.fill(
              child: Column(
                children: [
                  // Header inside grey background
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _leave(false),
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
                            child: Text(
                              _title,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                            ),
                          ),
                        ),
                        const SizedBox(width: 44, height: 44),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cards row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PeyapayPartyCardsStack(
                      left: PeyapayPartyCardData(
                        title: leftTitle,
                        subtitle: leftSubtitle,
                        icon: widget.sender?.icon ?? Icons.account_balance_wallet_outlined,
                        iconColor: widget.sender?.color ?? ink,
                      ),
                      right: PeyapayPartyCardData(
                        title: rightTitle,
                        subtitle: rightSubtitle,
                        icon: widget.recipient.icon ?? Icons.storefront_outlined,
                        iconColor: widget.recipient.color ?? ink,
                      ),
                      ink: ink,
                      muted: muted,
                      cardBg: Colors.white,
                      cutoutBg: topBg,
                      accent: green,
                      arrowBg: Colors.white,
                      arrowBorderColor: const Color(0xFFDDDDDD),
                      arrowIcon: Icons.chevron_right_rounded,
                      leftSlide: _leftSlide,
                      rightSlide: _rightSlide,
                      arrowFade: _arrowFade,
                      circleScale: _circleScale,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // White bottom container
            Positioned(
              left: 0,
              right: 0,
              top: 252,
              bottom: 0,
              child: FadeTransition(
                opacity: _sheetFade,
                child: SlideTransition(
                  position: _sheetSlide,
                  child: ScaleTransition(
                    scale: _sheetScale,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
                              child: Column(
                                children: [
                                  _detailRow(
                                    label: 'From',
                                    value: '$leftTitle - ${widget.sender?.subtitle ?? leftSubtitle}',
                                    ink: ink,
                                    muted: muted,
                                    icon: Icons.wallet_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _detailRow(
                                    label: widget.type == PeyapayTransactionType.deposit ? 'Amount added' : 'Amount',
                                    value: '${formatFrMoneySigned(widget.amount)} XOF',
                                    ink: ink,
                                    muted: muted,
                                    icon: Icons.payments_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _detailRow(
                                    label: widget.type == PeyapayTransactionType.transfer ? 'Transfer fees' : 'Fees',
                                    value: '${formatFrMoneySigned(widget.fee)} XOF',
                                    ink: ink,
                                    muted: muted,
                                    icon: Icons.receipt_long_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(height: 1, color: border.withValues(alpha: 0.6)),
                                  const SizedBox(height: 12),
                                  _detailRow(
                                    label: 'Recipient',
                                    value: '$rightTitle - $rightSubtitle',
                                    ink: ink,
                                    muted: muted,
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 12),
                                  _detailRow(
                                    label: 'Arrival',
                                    value: arrivedAt,
                                    ink: ink,
                                    muted: muted,
                                    icon: Icons.schedule,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted)),
                                    const Spacer(),
                                    Text(
                                      '${formatFrMoneySigned(total)} XOF',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: _SlideToPay(
                                    enabled: !_loading,
                                    label: switch (widget.type) {
                                      PeyapayTransactionType.transfer => 'Glisser pour transférer',
                                      PeyapayTransactionType.payment => 'Glisser pour payer',
                                      PeyapayTransactionType.deposit => 'Glisser pour confirmer',
                                    },
                                    onCompleted: _confirm,
                                    background: isDark ? cs.surfaceContainerHighest : const Color(0xFF111827),
                                    foreground: isDark ? Colors.white : const Color(0xFF6B7280),
                                    textColor: Colors.white,
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
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

Widget _detailRow({
  required String label,
  required String value,
  required Color ink,
  required Color muted,
  required IconData icon,
}) {
  return Row(
    children: [
      Icon(icon, size: 18, color: ink),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: muted.withValues(alpha: 0.9)),
        ),
      ),
    ],
  );
}

Widget _receiptRow(
  String k,
  String v,
  Color ink,
  Color muted, {
  TextStyle? valueStyle,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          k,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          v,
          textAlign: TextAlign.end,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: valueStyle ?? TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
        ),
      ),
    ],
  );
}

class _SlideToPay extends StatefulWidget {
  const _SlideToPay({
    required this.enabled,
    required this.label,
    required this.onCompleted,
    required this.background,
    required this.foreground,
    required this.textColor,
  });

  final bool enabled;
  final String label;
  final Future<void> Function() onCompleted;
  final Color background;
  final Color foreground;
  final Color textColor;

  @override
  State<_SlideToPay> createState() => _SlideToPayState();
}

class _SlideToPayState extends State<_SlideToPay> {
  double _dragX = 0;
  bool _done = false;
  bool _loading = false;

  Future<void> _finish() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    await widget.onCompleted();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const h = 54.0;
    const thumb = 46.0;

    return LayoutBuilder(
      builder: (context, c) {
        final maxLocal = c.maxWidth - thumb;
        final x = _dragX.clamp(0.0, maxLocal).toDouble();
        final double progress =
            maxLocal <= 0 ? 0.0 : (x / maxLocal).clamp(0.0, 1.0).toDouble();

        return AbsorbPointer(
          absorbing: !widget.enabled || _loading || _done,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: _loading ? 0.0 : 1.0,
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: widget.textColor.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: thumb + (x * 0.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(color: widget.foreground.withValues(alpha: 0.18)),
                    ),
                  ),
                ),
                Positioned(
                  left: x,
                  top: ((h - thumb) / 2).toDouble(),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) {
                      setState(() => _dragX = (_dragX + d.delta.dx).clamp(0, maxLocal));
                    },
                    onHorizontalDragEnd: (_) async {
                      if (_dragX >= maxLocal * 0.92) {
                        setState(() => _dragX = maxLocal);
                        await _finish();
                      } else {
                        setState(() => _dragX = 0);
                      }
                    },
                    child: Container(
                      width: thumb,
                      height: thumb,
                      decoration: BoxDecoration(
                        color: widget.foreground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


