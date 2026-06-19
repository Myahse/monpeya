import 'package:flutter/material.dart';

typedef LeadwayExitHandler = void Function(BuildContext context);

class LeadwayPaymentRequest {
  const LeadwayPaymentRequest({
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

typedef LeadwayPaymentHandler = Future<bool> Function(
  BuildContext context,
  LeadwayPaymentRequest request,
);

/// Registered by Mon Peya before opening Leadway Assurance.
class LeadwayHostBridge {
  LeadwayHostBridge._();

  static LeadwayExitHandler? onExitModule;
  static LeadwayPaymentHandler? onPayment;

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
    LeadwayPaymentRequest request,
  ) async {
    final handler = onPayment;
    if (handler == null) {
      throw StateError('LeadwayHostBridge.onPayment not configured by Mon Peya shell.');
    }
    return handler(context, request);
  }
}
