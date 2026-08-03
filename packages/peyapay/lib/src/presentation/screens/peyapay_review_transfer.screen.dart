import 'dart:async';

import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/core/utils/peyapay_transfer.util.dart';
import 'package:peyapay/src/data/models/peyapay_client_transfer.model.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_party_cards_stack.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_review_animations.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_review_transfer_layout.util.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_slide_to_confirm.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transfer_receipt_sheet.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transfer_success_sheet.widget.dart';
import 'package:peyapay/src/presentation/widgets/review_transfer_sheet.widget.dart' show PeyapayRecipient, PeyapaySender, PeyapayTransactionType;

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
  bool _successShown = false;
  bool _leaving = false;
  /// Slide-to-confirm completed (mock payment / deposit treated as paid).
  bool _slideConfirmed = false;

  late final AnimationController _anim;
  late final PeyapayReviewEntranceAnimations _entrance;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: PeyapayReviewEntranceAnimations.entranceDuration);
    _entrance = PeyapayReviewEntranceAnimations(_anim);
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
    if (_successShown) return;

    late final Future<PeyapayClientTransferResult?> paymentFuture;
    if (widget.type == PeyapayTransactionType.transfer) {
      final recipientPhone = widget.recipient.reference?.trim();
      if (recipientPhone == null || recipientPhone.isEmpty) {
        await _showError('Numéro destinataire manquant');
        throw StateError('missing recipient phone');
      }
      paymentFuture = peyapayExecuteClientTransfer(
        recipientPhone: recipientPhone,
        amountReceived: widget.amount,
        fee: widget.fee,
      );
    } else {
      // Mock payment / deposit — treat slide confirm as paid for callers (e.g. billetterie).
      _slideConfirmed = true;
      paymentFuture = Future<PeyapayClientTransferResult?>.delayed(
        const Duration(milliseconds: 650),
        () => null,
      );
    }

    if (!mounted) return;
    setState(() => _successShown = true);

    // Open success modal immediately — do not wait for the review exit animation.
    unawaited(_finishAfterSuccessModal(paymentFuture));
    unawaited(
      _anim.animateTo(
        0,
        duration: PeyapayReviewEntranceAnimations.confirmExitDuration,
        curve: Curves.easeInCubic,
      ),
    );
  }

  Future<void> _finishAfterSuccessModal(
    Future<PeyapayClientTransferResult?> paymentFuture,
  ) async {
    final action = await _showSuccessAndReceipt(paymentFuture: paymentFuture);
    if (!mounted) return;

    var succeeded = false;
    if (widget.type == PeyapayTransactionType.transfer) {
      try {
        await paymentFuture;
        succeeded = true;
      } on Object {
        succeeded = false;
      }
    } else {
      // Payment / deposit: slide confirm already marks success so buy can persist.
      succeeded = _slideConfirmed;
    }

    if (action == PeyapayTransferDismissAction.goHome) {
      if (widget.type == PeyapayTransactionType.deposit) {
        widget.onDepositComplete?.call();
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      Navigator.of(context).pop(succeeded);
      return;
    }

    // Stayed on review after receipt — still return success for mock payment so
    // billetterie can POST /v1/tickets/buy when the route is eventually popped.
    if (succeeded && widget.type == PeyapayTransactionType.payment) {
      // Keep review visible; next back/_leave will pop(true).
      await _restoreReviewAfterModal();
      return;
    }

    await _restoreReviewAfterModal();
  }

  Future<void> _restoreReviewAfterModal() async {
    await _anim.animateTo(
      1,
      duration: PeyapayReviewEntranceAnimations.entranceDuration,
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() => _successShown = false);
  }

  Future<void> _showError(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Échec'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<PeyapayTransferDismissAction?> _showSuccessAndReceipt({
    required Future<PeyapayClientTransferResult?> paymentFuture,
  }) {
    final txDate = DateTime.now();

    Future<void> openReceipt() async {
      String? txId;
      try {
        final result = await paymentFuture;
        txId = result?.numeroOperation ?? result?.trId;
      } on Object {
        // Receipt still opens if payment is pending or failed.
      }

      if (!mounted) return;
      await showPeyapayTransferReceiptSheet(
        context: context,
        type: widget.type,
        amount: widget.amount,
        fee: widget.fee,
        recipient: widget.recipient,
        sender: widget.sender,
        transactionId: txId,
        transactionDate: txDate,
      );
    }

    return showPeyapayTransferSuccessSheet(
      context: context,
      type: widget.type,
      amount: widget.amount,
      fee: widget.fee,
      recipient: widget.recipient,
      sender: widget.sender,
      paymentFuture: paymentFuture,
      onReceipt: openReceipt,
    );
  }

  Future<void> _leave([bool? result]) async {
    if (_leaving) return;
    _leaving = true;
    await _anim.animateTo(
      0,
      duration: PeyapayReviewEntranceAnimations.exitDuration,
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;
    final popResult = result ??
        (widget.type == PeyapayTransactionType.payment && _slideConfirmed
            ? true
            : false);
    Navigator.of(context).pop(popResult);
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
    final cardBg = isDark ? cs.surfaceContainerHigh : Colors.white;
    final cardBorder = isDark ? border : null;
    final arrowBg = isDark ? cs.surfaceContainerHigh : Colors.white;
    final arrowBorder = isDark ? border : const Color(0xFFDDDDDD);
    final padding = MediaQuery.paddingOf(context);
    final bodyHeight = MediaQuery.sizeOf(context).height -
        padding.top -
        (isDark ? padding.bottom : 0);
    final sheetTop = PeyapayReviewTransferLayout.sheetTop(
      bodyHeight: bodyHeight,
      isDark: isDark,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leave(false);
      },
      child: Scaffold(
        backgroundColor: topBg,
        body: SafeArea(
          bottom: isDark,
          child: Stack(
          clipBehavior: Clip.none,
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

                  // Cards row — full width so cards can enter from screen edges.
                  ClipRect(
                    clipBehavior: Clip.none,
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
                      cardBg: cardBg,
                      cardBorderColor: cardBorder,
                      cutoutBg: topBg,
                      accent: green,
                      arrowBg: arrowBg,
                      arrowBorderColor: arrowBorder,
                      arrowIcon: Icons.chevron_right_rounded,
                      cardsReveal: _entrance.cardsReveal,
                      arrowFade: _entrance.arrowFade,
                      circleScale: _entrance.circleScale,
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
              top: sheetTop,
              bottom: 0,
              child: FadeTransition(
                opacity: _entrance.sheetFade,
                child: SlideTransition(
                  position: _entrance.sheetSlide,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _detailRow(
                                            label: 'From',
                                            value: leftTitle,
                                            ink: ink,
                                            muted: muted,
                                            icon: Icons.wallet_outlined,
                                          ),
                                          const SizedBox(height: 20),
                                          _detailRow(
                                            label: widget.type == PeyapayTransactionType.deposit
                                                ? 'Amount added'
                                                : 'Amount',
                                            value: '${formatFrMoneySigned(widget.amount)} XOF',
                                            ink: ink,
                                            muted: muted,
                                            icon: Icons.payments_outlined,
                                          ),
                                          const SizedBox(height: 20),
                                          _detailRow(
                                            label: widget.type == PeyapayTransactionType.transfer
                                                ? 'Transfer fees'
                                                : 'Fees',
                                            value: widget.fee == 0
                                                ? 'Gratuit'
                                                : '${formatFrMoneySigned(widget.fee)} XOF',
                                            ink: ink,
                                            muted: muted,
                                            icon: Icons.receipt_long_outlined,
                                            valueColor: widget.fee == 0 ? green : ink,
                                          ),
                                          const SizedBox(height: 20),
                                          Container(
                                            height: 1,
                                            color: border.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(height: 20),
                                          _detailRow(
                                            label: 'Recipient',
                                            value: '$rightTitle - $rightSubtitle',
                                            ink: ink,
                                            muted: muted,
                                            icon: Icons.arrow_downward_rounded,
                                          ),
                                          const SizedBox(height: 20),
                                          _detailRow(
                                            label: 'Arrive at',
                                            value: arrivedAt,
                                            ink: ink,
                                            muted: muted,
                                            icon: Icons.calendar_today_outlined,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: muted,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${formatFrMoneySigned(total)} XOF',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  AnimatedOpacity(
                                    opacity: _successShown ? 0 : 1,
                                    duration: const Duration(milliseconds: 120),
                                    child: IgnorePointer(
                                      ignoring: _successShown,
                                      child: PeyapaySlideToConfirm(
                                        enabled: !_successShown,
                                        label: switch (widget.type) {
                                          PeyapayTransactionType.transfer =>
                                            'Glisser pour transférer',
                                          PeyapayTransactionType.payment => 'Glisser pour payer',
                                          PeyapayTransactionType.deposit =>
                                            'Glisser pour confirmer',
                                        },
                                        onCompleted: _confirm,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
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
  Color? valueColor,
}) {
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
      const SizedBox(width: 12),
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

