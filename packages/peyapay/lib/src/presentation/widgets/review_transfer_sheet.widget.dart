import 'dart:async';

import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/core/utils/peyapay_transfer.util.dart';
import 'package:peyapay/src/data/models/peyapay_client_transfer.model.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transfer_receipt_sheet.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transfer_success_sheet.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_party_cards_stack.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_review_transfer_layout.util.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_review_animations.widget.dart';

enum PeyapayTransactionType { payment, transfer, deposit }

class PeyapaySender {
  const PeyapaySender({
    required this.title,
    required this.subtitle,
    this.icon,
    this.color,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? color;
}

class PeyapayRecipient {
  const PeyapayRecipient({
    required this.name,
    this.reference,
    this.icon,
    this.color,
  });

  final String name;
  final String? reference;
  final IconData? icon;
  final Color? color;
}

Future<bool?> showPeyapayReviewTransferSheet({
  required BuildContext context,
  required PeyapayTransactionType type,
  required int amount,
  required PeyapayRecipient recipient,
  PeyapaySender? sender,
  int fee = 0,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PeyapayReviewTransferSheet(
      type: type,
      amount: amount,
      fee: fee,
      recipient: recipient,
      sender: sender,
    ),
  );
}

class _PeyapayReviewTransferSheet extends StatefulWidget {
  const _PeyapayReviewTransferSheet({
    required this.type,
    required this.amount,
    required this.fee,
    required this.recipient,
    required this.sender,
  });

  final PeyapayTransactionType type;
  final int amount;
  final int fee;
  final PeyapayRecipient recipient;
  final PeyapaySender? sender;

  @override
  State<_PeyapayReviewTransferSheet> createState() => _PeyapayReviewTransferSheetState();
}

class _PeyapayReviewTransferSheetState extends State<_PeyapayReviewTransferSheet>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _successShown = false;

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

  Future<void> _confirm() async {
    if (_successShown) return;

    late final Future<PeyapayClientTransferResult?> paymentFuture;
    if (widget.type == PeyapayTransactionType.transfer) {
      final recipientPhone = widget.recipient.reference?.trim();
      if (recipientPhone == null || recipientPhone.isEmpty) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Échec'),
            content: const Text('Numéro destinataire manquant'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      paymentFuture = peyapayExecuteClientTransfer(
        recipientPhone: recipientPhone,
        amountReceived: widget.amount,
        fee: widget.fee,
      );
    } else {
      paymentFuture = Future<PeyapayClientTransferResult?>.delayed(
        const Duration(milliseconds: 650),
        () => null,
      );
    }

    if (!mounted) return;
    setState(() => _successShown = true);

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
      succeeded = action == PeyapayTransferDismissAction.goHome;
    }

    if (action == PeyapayTransferDismissAction.goHome) {
      Navigator.of(context).pop(succeeded);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final topBg = isDark ? cs.surface : const Color(0xFFEBEBEB);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final cardBg = isDark ? cs.surfaceContainerHigh : Colors.white;
    final cardBorder = isDark ? border : null;
    final arrowBg = isDark ? cs.surfaceContainerHigh : Colors.white;
    final arrowBorder = isDark ? border : const Color(0xFFDDDDDD);

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
    final screenH = MediaQuery.sizeOf(context).height;
    final padding = MediaQuery.paddingOf(context);
    final sheetBodyHeight = (isDark ? screenH * 0.88 : screenH) -
        (isDark ? padding.bottom : 0);
    final sheetTop = PeyapayReviewTransferLayout.sheetTop(
      bodyHeight: sheetBodyHeight,
      isDark: isDark,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        bottom: isDark,
        child: SizedBox(
          height: isDark ? screenH * 0.88 : screenH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
                // Grey top background
                Positioned.fill(
                  child: Container(color: topBg),
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
                      border: Border.all(color: isDark ? Colors.white : cs.outlineVariant, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                        Container(height: 1, color: border.withValues(alpha: 0.6)),
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
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _loading ? null : _confirm,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text(
                                            'Confirmer',
                                            style: TextStyle(fontWeight: FontWeight.w900),
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

                // Header + Cards on grey area (top)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).maybePop(false),
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
                    ],
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

