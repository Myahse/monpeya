import 'package:flutter/material.dart';

import 'peyapay_card_brand_badge.dart';

/// RN `SuccessModal` after debit card link — Visa logo, Add money now, Back home.
class PeyapayCardLinkSuccessDialog extends StatefulWidget {
  const PeyapayCardLinkSuccessDialog({
    super.key,
    required this.cardType,
    required this.onAddMoney,
    required this.onBackHome,
    required this.onRetry,
  });

  final String cardType;
  final Future<void> Function() onAddMoney;
  final VoidCallback onBackHome;
  final VoidCallback onRetry;

  @override
  State<PeyapayCardLinkSuccessDialog> createState() => _PeyapayCardLinkSuccessDialogState();
}

class _PeyapayCardLinkSuccessDialogState extends State<PeyapayCardLinkSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  late final Animation<double> _slideY;
  late final Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    // Slide up from below (RN SuccessModal uses translateY from bottom).
    _slideY = Tween<double>(begin: 120, end: 0).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slide,
        curve: const Interval(0.35, 1, curve: Curves.easeOut),
      ),
    );
    _slide.forward();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  bool get _recognized => widget.cardType == 'VISA' || widget.cardType == 'MASTERCARD';

  Future<void> _closeThen(Future<void> Function() action) async {
    await _slide.reverse();
    if (!mounted) return;
    await action();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => _closeThen(() async => widget.onBackHome()),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 20 + MediaQuery.paddingOf(context).bottom,
              ),
              child: GestureDetector(
              onTap: () {},
              child: AnimatedBuilder(
                animation: _slide,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(0, _slideY.value),
                    child: Opacity(
                      opacity: _slide.value.clamp(0.0, 1.0),
                      child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PeyapayCardBrandBadge(
                        cardType: widget.cardType,
                        logoOpacity: _logoFade.value,
                        recognized: _recognized,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _recognized ? 'Debit card linked!' : 'Card Not Recognized',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recognized
                            ? 'Your bank account has been successfully connected through debit card. you can now add money to your main account.'
                            : 'We couldn\'t identify your card type. Please try again with a supported card.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF555555)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _recognized
                              ? () => _closeThen(widget.onAddMoney)
                              : () => _closeThen(() async => widget.onRetry()),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF006D56),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _recognized ? 'Add money now' : 'Try again',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _closeThen(() async => widget.onBackHome()),
                        child: const Text(
                          'Back home',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                    ),
                  );
                },
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
