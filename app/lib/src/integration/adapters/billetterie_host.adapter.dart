import 'package:billetterie/billetterie.dart';
import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

/// Connects Mon Peya Peya Pay to the independent Billetterie package.
class MonPeyaBilletterieHostAdapter {
  MonPeyaBilletterieHostAdapter._();

  static void register() {
    BilletterieHostBridge.onPayment = _handlePayment;
    BilletterieHostBridge.onExitModule = _exitToMonPeyaHome;
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
    BilletteriePaymentRequest request,
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
            icon: Icons.confirmation_number_outlined,
            color: const Color(0xFF0284C7),
          ),
        ),
      ),
    );
    return result == true;
  }
}
