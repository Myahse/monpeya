import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

enum BilletterieResultKind { success, error, info }

/// Shared result modal for Billetterie (replaces snackbars / debug banners).
Future<void> showBilletterieResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  BilletterieResultKind kind = BilletterieResultKind.info,
  String confirmLabel = 'OK',
  BilletterieBrand? brand,
}) {
  final palette = brand ?? BilletterieBrand.of(context);
  final (icon, iconColor, iconBg) = switch (kind) {
    BilletterieResultKind.success => (
        Icons.check_rounded,
        const Color(0xFF059669),
        const Color(0xFF059669).withValues(alpha: 0.12),
      ),
    BilletterieResultKind.error => (
        Icons.error_outline_rounded,
        palette.danger,
        palette.danger.withValues(alpha: 0.12),
      ),
    BilletterieResultKind.info => (
        Icons.info_outline_rounded,
        palette.primaryDark,
        palette.primarySoft.withValues(alpha: 0.55),
      ),
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: kind != BilletterieResultKind.success,
    builder: (context) {
      return AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: palette.muted,
                    height: 1.35,
                  ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ),
        ],
      );
    },
  );
}

/// Modal shown after a successful ticket purchase.
Future<void> showTicketPurchaseSuccessDialog(
  BuildContext context, {
  String? orderRef,
  String? routeLabel,
}) {
  final brand = BilletterieBrand.of(context);
  final order = orderRef?.trim();
  final route = routeLabel?.trim();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF059669),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Achat confirmé',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: brand.text,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              order != null && order.isNotEmpty
                  ? 'Votre billet a été acheté avec succès.\nRéférence : $order'
                  : 'Votre billet a été acheté avec succès.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: brand.muted,
                    height: 1.35,
                  ),
            ),
            if (route != null && route.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                route,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: brand.text,
                    ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: brand.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Voir mon billet'),
            ),
          ),
        ],
      );
    },
  );
}

/// Simple error modal for purchase failures.
Future<void> showTicketPurchaseErrorDialog(
  BuildContext context, {
  required String message,
}) {
  return showBilletterieResultDialog(
    context,
    title: 'Échec du paiement',
    message: message,
    kind: BilletterieResultKind.error,
  );
}
