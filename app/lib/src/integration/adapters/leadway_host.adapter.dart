import 'package:flutter/material.dart';
import 'package:leadway/leadway.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

/// Connects Mon Peya navigation to the Leadway Assurance package.
class MonPeyaLeadwayHostAdapter {
  MonPeyaLeadwayHostAdapter._();

  static void register() {
    LeadwayHostBridge.onExitModule = _exitToMonPeyaHome;
    LeadwayHostBridge.onPayment = _handlePayment;
  }

  static void _exitToMonPeyaHome(BuildContext context) {
    final stack = AppStackScope.maybeOf(context);
    if (stack != null && stack.canGoBack) {
      stack.goBack();
      return;
    }
    Navigator.of(context).maybePop();
  }

  static Future<bool> _handlePayment(
    BuildContext context,
    LeadwayPaymentRequest request,
  ) async {
    if (!context.mounted) return false;
    final ok = await ModuleAuth.ensureRegistered(context);
    if (!ok || !context.mounted) return false;

    final sender = await peyapayPrimarySender();
    if (!context.mounted) return false;

    final result = await Navigator.of(context).push<bool>(
      peyapayReviewTransferRoute(
        PeyapayReviewTransferScreen(
          type: PeyapayTransactionType.payment,
          amount: request.amount,
          fee: 0,
          sender: sender,
          recipient: PeyapayRecipient(
            name: request.recipientName,
            reference: request.reference ?? request.label,
            icon: Icons.two_wheeler_outlined,
            color: const Color(0xFF006D56),
          ),
        ),
      ),
    );
    return result == true;
  }
}
