import 'dart:async';

import 'package:flutter/material.dart';

import 'package:peyapay/src/data/models/peyapay_api.exception.dart';
import 'package:peyapay/src/data/models/peyapay_client_transfer.model.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transfer_modal_shared.widget.dart';
import 'package:peyapay/src/presentation/widgets/review_transfer_sheet.widget.dart';

enum PeyapayTransferDismissAction { goHome, stayOnReview }

/// Success modal — opens immediately; pill confirms when [paymentFuture] completes.
Future<PeyapayTransferDismissAction?> showPeyapayTransferSuccessSheet({
  required BuildContext context,
  required PeyapayTransactionType type,
  required int amount,
  required int fee,
  required PeyapayRecipient recipient,
  required Future<PeyapayClientTransferResult?> paymentFuture,
  PeyapaySender? sender,
  Future<void> Function()? onReceipt,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<PeyapayTransferDismissAction>(
    PageRouteBuilder<PeyapayTransferDismissAction>(
      opaque: false,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PeyapayTransferSuccessSheet(
          type: type,
          amount: amount,
          fee: fee,
          recipient: recipient,
          sender: sender,
          paymentFuture: paymentFuture,
          onReceipt: onReceipt,
          openAnimation: animation,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    ),
  );
}

class PeyapayTransferSuccessSheet extends StatefulWidget {
  const PeyapayTransferSuccessSheet({
    super.key,
    required this.type,
    required this.amount,
    required this.fee,
    required this.recipient,
    required this.paymentFuture,
    this.sender,
    this.onReceipt,
    this.openAnimation,
  });

  final PeyapayTransactionType type;
  final int amount;
  final int fee;
  final PeyapayRecipient recipient;
  final PeyapaySender? sender;
  final Future<PeyapayClientTransferResult?> paymentFuture;
  final Future<void> Function()? onReceipt;
  final Animation<double>? openAnimation;

  @override
  State<PeyapayTransferSuccessSheet> createState() => _PeyapayTransferSuccessSheetState();
}

class _PeyapayTransferSuccessSheetState extends State<PeyapayTransferSuccessSheet>
    with SingleTickerProviderStateMixin {
  static const _panelHeightFactor = 0.68;
  static const _pillClipHeight = 36.0;
  static const _pillTopInset = 2.0;

  late final AnimationController _pillEnter;
  late final DateTime _transactionDate;

  bool _paymentSucceeded = false;
  bool _paymentFailed = false;
  String? _errorMessage;
  String? _resolvedTxId;

  @override
  void initState() {
    super.initState();
    _transactionDate = DateTime.now();
    _pillEnter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    unawaited(_resolvePayment());
  }

  Future<void> _resolvePayment() async {
    try {
      final result = await widget.paymentFuture;
      if (!mounted) return;
      await _waitForModalEntrance();
      if (!mounted) return;
      final id = result?.numeroOperation ?? result?.trId;
      setState(() {
        _paymentSucceeded = true;
        _resolvedTxId = id;
      });
      _pillEnter.forward(from: 0);
    } on Object catch (error) {
      if (!mounted) return;
      await _waitForModalEntrance();
      if (!mounted) return;
      setState(() {
        _paymentFailed = true;
        _errorMessage = error is PeyapayApiException
            ? error.message
            : 'Impossible d\'effectuer l\'opération';
      });
    }
  }

  Future<void> _waitForModalEntrance() async {
    final anim = widget.openAnimation;
    if (anim == null || anim.status == AnimationStatus.completed) return;
    final done = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        anim.removeStatusListener(onStatus);
        if (!done.isCompleted) done.complete();
      }
    }

    anim.addStatusListener(onStatus);
    if (anim.status == AnimationStatus.completed) {
      anim.removeStatusListener(onStatus);
      return;
    }
    return done.future;
  }

  @override
  void dispose() {
    _pillEnter.dispose();
    super.dispose();
  }

  String get _txId {
    final id = _resolvedTxId?.trim();
    if (id != null && id.isNotEmpty) return '#$id';
    if (!_paymentSucceeded && !_paymentFailed) return '—';
    return '#${DateTime.now().millisecondsSinceEpoch}';
  }

  String get _senderTitle => widget.sender?.title ?? 'Compte principal';
  String get _senderSubtitle => widget.sender?.subtitle ?? 'PeyaPay';

  String get _recipientRef => widget.recipient.reference?.trim().isNotEmpty == true
      ? widget.recipient.reference!.trim()
      : widget.recipient.name;

  Future<void> _closeHome() async {
    if (_paymentSucceeded) {
      await _pillEnter.reverse();
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(
      _paymentSucceeded
          ? PeyapayTransferDismissAction.goHome
          : PeyapayTransferDismissAction.stayOnReview,
    );
  }

  Future<void> _openReceipt() async {
    final open = widget.onReceipt;
    if (open == null) return;
    if (_paymentSucceeded) {
      await _pillEnter.reverse();
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(PeyapayTransferDismissAction.stayOnReview);
    await open();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    const green = Color(0xFF006D56);

    final screenH = MediaQuery.sizeOf(context).height;
    final panelH = screenH * _panelHeightFactor;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final openAnim = widget.openAnimation ?? const AlwaysStoppedAnimation(1.0);
    final panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: openAnim, curve: Curves.easeOutCubic));
    final panelScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: openAnim, curve: Curves.easeOutCubic),
    );
    final pillSlide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pillEnter, curve: Curves.easeOutCubic));

    const modalShape = BorderRadius.all(Radius.circular(24));

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          FadeTransition(
            opacity: CurvedAnimation(parent: openAnim, curve: Curves.easeOut),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          ),
          Positioned(
            left: isDark ? 12 : 0,
            right: isDark ? 12 : 0,
            bottom: isDark ? 12 : 16,
            height: panelH,
            child: SlideTransition(
              position: panelSlide,
              child: ScaleTransition(
                scale: panelScale,
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: modalShape,
                    border: Border.all(color: border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: modalShape,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRect(
                          child: SizedBox(
                            height: _pillClipHeight,
                            width: double.infinity,
                            child: _paymentSucceeded
                                ? SlideTransition(
                                    position: pillSlide,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: _pillTopInset),
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: PeyapayTransferStatusPill(
                                          label: peyapayTransferStatusLabel(widget.type),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        if (_paymentFailed && _errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB42318),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Expanded(
                          child: PeyapayTransferResultPanel(
                            amount: widget.amount,
                            fee: widget.fee,
                            type: widget.type,
                            recipient: widget.recipient,
                            recipientRef: _recipientRef,
                            senderTitle: _senderTitle,
                            senderSubtitle: _senderSubtitle,
                            txId: _txId,
                            txDate: peyapayTransferEnglishDate(_transactionDate),
                            categoryLabel: peyapayTransferCategoryLabel(widget.type),
                            ink: ink,
                            muted: muted,
                            border: border,
                            green: green,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, 4, 24, 8 + bottomPad),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isDark ? cs.onSurface : const Color(0xFF111827),
                                    foregroundColor: isDark ? cs.surface : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: isDark ? BorderSide(color: border) : BorderSide.none,
                                    ),
                                  ),
                                  onPressed: _closeHome,
                                  child: const Text(
                                    'Retour à l\'accueil',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: widget.onReceipt == null ? null : _openReceipt,
                                icon: Icon(Icons.description_outlined, size: 18, color: muted),
                                label: Text(
                                  'Obtenir le reçu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: muted,
                                    fontSize: 14,
                                  ),
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
    );
  }
}
