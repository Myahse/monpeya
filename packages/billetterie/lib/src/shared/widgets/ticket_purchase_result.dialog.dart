import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

/// Modal shown after a successful ticket purchase (replaces snackbar).
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
              'Billet enregistre',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: brand.text,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              order != null && order.isNotEmpty
                  ? 'Votre paiement a ete enregistre.\nReference : $order'
                  : 'Votre paiement a ete enregistre dans ticketing.',
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

/// Simple error modal (same style family as success).
Future<void> showTicketPurchaseErrorDialog(
  BuildContext context, {
  required String message,
}) {
  final brand = BilletterieBrand.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Echec du paiement',
          style: TextStyle(color: brand.text, fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: brand.muted,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: brand.primaryDark)),
          ),
        ],
      );
    },
  );
}
