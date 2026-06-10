import 'package:flutter/material.dart';

import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/presentation/widgets/review_transfer_sheet.widget.dart';

/// Default wallet sender built from the Mon Peya shell session.
Future<PeyapaySender?> peyapayPrimarySender() async {
  final auth = PeyapayHostBridge.auth;
  if (auth == null) return null;

  if (!await auth.isSessionActive()) return null;

  final phone = await auth.getPhone();
  final subtitle = _maskPhone(phone);

  return PeyapaySender(
    title: 'Compte principal',
    subtitle: subtitle,
    icon: Icons.account_balance_wallet_outlined,
    color: const Color(0xFF006D56),
  );
}

String _maskPhone(String? phone) {
  if (phone == null || phone.isEmpty) return 'Compte PeyaPay';
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 4) {
    return 'PeyaPay • ${digits.substring(digits.length - 4)}';
  }
  return phone;
}
