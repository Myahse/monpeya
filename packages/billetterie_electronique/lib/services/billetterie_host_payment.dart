import 'dart:convert';

import 'package:flutter/material.dart';

import '../host/billetterie_host_bridge.dart';

/// Helpers for ticket IDs and QR payloads (payment goes through [BilletterieHostBridge]).
class BilletterieHostPayment {
  static Future<bool> requestPayment({
    required BuildContext context,
    required int amount,
    required String recipientName,
    required String label,
    String? reference,
  }) {
    return BilletterieHostBridge.requestPayment(
      context,
      BilletteriePaymentRequest(
        amount: amount,
        recipientName: recipientName,
        label: label,
        reference: reference,
      ),
    );
  }
}

String makeTicketId(String prefix) =>
    '$prefix-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond.toRadixString(16)}';

String encodeQrPayload(Map<String, dynamic> payload) => jsonEncode(payload);
