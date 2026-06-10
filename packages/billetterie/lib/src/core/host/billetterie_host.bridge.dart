import 'package:flutter/material.dart';

/// Payment request forwarded to Mon Peya Peya Pay.
class BilletteriePaymentRequest {
  const BilletteriePaymentRequest({
    required this.amount,
    required this.recipientName,
    required this.label,
    this.reference,
  });

  final int amount;
  final String recipientName;
  final String label;
  final String? reference;
}

typedef BilletteriePaymentHandler = Future<bool> Function(
  BuildContext context,
  BilletteriePaymentRequest request,
);

typedef BilletterieExitHandler = void Function(BuildContext context);

/// Registered by Mon Peya before opening Billetterie.
class BilletterieHostBridge {
  BilletterieHostBridge._();

  static BilletteriePaymentHandler? onPayment;
  static BilletterieExitHandler? onExitModule;

  /// Leave Billetterie and return to the Mon Peya shell (home tabs).
  static void exitModule(BuildContext context) {
    final handler = onExitModule;
    if (handler != null) {
      handler(context);
      return;
    }
    Navigator.of(context).maybePop();
  }

  static Future<bool> requestPayment(
    BuildContext context,
    BilletteriePaymentRequest request,
  ) async {
    if (request.amount <= 0) return true;
    final handler = onPayment;
    if (handler == null) {
      throw StateError('BilletterieHostBridge.onPayment not configured by Mon Peya shell.');
    }
    return handler(context, request);
  }
}
