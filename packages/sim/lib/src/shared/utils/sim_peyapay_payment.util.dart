import 'package:flutter/material.dart';

import 'package:sim/src/core/host/sim_host.bridge.dart';

abstract final class SimPeyapayPaymentUtil {
  SimPeyapayPaymentUtil._();

  static Future<bool> collectPremium(
    BuildContext context, {
    required int amount,
    required String label,
    String? reference,
  }) async {
    if (amount <= 0) return true;
    if (!context.mounted) return false;

    return SimHostBridge.requestPayment(
      context,
      SimPaymentRequest(
        amount: amount,
        recipientName: 'SIM Assurances',
        label: label,
        reference: reference,
      ),
    );
  }
}
