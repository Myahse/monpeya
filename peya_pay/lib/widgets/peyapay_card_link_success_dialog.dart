import 'package:flutter/material.dart';

import 'peyapay_card_brand_badge.dart';
import 'peyapay_draggable_bottom_sheet.dart';

/// Bottom sheet shown after debit card link — Visa logo, Add money now, Back home.
class PeyapayCardLinkSuccessDialog extends StatefulWidget {
  const PeyapayCardLinkSuccessDialog({
    super.key,
    required this.cardType,
    required this.onDismiss,
    required this.onAddMoney,
    required this.onBackHome,
    required this.onRetry,
  });

  final String cardType;
  final VoidCallback onDismiss;
  final Future<void> Function() onAddMoney;
  final VoidCallback onBackHome;
  final VoidCallback onRetry;

  @override
  State<PeyapayCardLinkSuccessDialog> createState() => _PeyapayCardLinkSuccessDialogState();
}

class _PeyapayCardLinkSuccessDialogState extends State<PeyapayCardLinkSuccessDialog>
    with SingleTickerProviderStateMixin {
  final _sheetKey = GlobalKey<PeyapayDraggableBottomSheetState>();
  late final AnimationController _logoFade;

  @override
  void initState() {
    super.initState();
    _logoFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _logoFade.dispose();
    super.dispose();
  }

  bool get _recognized => widget.cardType == 'VISA' || widget.cardType == 'MASTERCARD';

  Future<void> _closeThen(VoidCallback action) async {
    await _sheetKey.currentState?.dismiss();
    action();
  }

  Future<void> _closeThenAsync(Future<void> Function() action) async {
    await _sheetKey.currentState?.dismiss();
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;

    return PeyapayDraggableBottomSheet(
      key: _sheetKey,
      onDismiss: widget.onDismiss,
      heightFactor: 0.48,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8, 4, 8, 8 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeTransition(
              opacity: CurvedAnimation(parent: _logoFade, curve: Curves.easeOut),
              child: PeyapayCardBrandBadge(
                cardType: widget.cardType,
                recognized: _recognized,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _recognized ? 'Carte bancaire liée !' : 'Carte non reconnue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
            ),
            const SizedBox(height: 8),
            Text(
              _recognized
                  ? 'Votre compte bancaire a été connecté via carte bancaire. Vous pouvez maintenant alimenter votre compte principal.'
                  : 'Nous n\'avons pas pu identifier votre type de carte. Réessayez avec une carte prise en charge.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.35, color: muted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _recognized
                    ? () => _closeThenAsync(widget.onAddMoney)
                    : () => _closeThen(widget.onRetry),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006D56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _recognized ? 'Ajouter de l\'argent' : 'Réessayer',
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
              onPressed: () => _closeThen(widget.onBackHome),
              child: Text(
                'Retour à l\'accueil',
                style: TextStyle(fontWeight: FontWeight.w800, color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
