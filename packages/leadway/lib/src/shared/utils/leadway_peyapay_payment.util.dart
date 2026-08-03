import 'package:flutter/material.dart';

import 'package:leadway/src/core/host/leadway_host.bridge.dart';


abstract final class LeadwayPeyapayPaymentUtil {
  LeadwayPeyapayPaymentUtil._();


  static Future<String?> ensureLoggedInPhone(BuildContext context) async {
    final loggedIn = await LeadwayHostBridge.ensureLoggedIn(context);
    if (!loggedIn || !context.mounted) return null;

    final phone = await LeadwayHostBridge.requireAuth.getPhone();
    final trimmed = phone?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return formatPhoneForLeadway(trimmed);
  }

  static String formatPhoneForLeadway(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final local = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
      return '+225 ${local.substring(0, 2)} ${local.substring(2, 4)} '
          '${local.substring(4, 6)} ${local.substring(6, 8)} ${local.substring(8)}';
    }
    return phone.trim();
  }


  static Future<bool> collectWalletPayment(
    BuildContext context, {
    required int amount,
    required String label,
    String? reference,
  }) async {
    if (amount <= 0) return true;
    if (!context.mounted) return false;

    return LeadwayHostBridge.requestPayment(
      context,
      LeadwayPaymentRequest(
        amount: amount,
        recipientName: 'Leadway Assurance',
        label: label,
        reference: reference,
      ),
    );
  }
}
