import 'package:billetterie_electronique/host/billetterie_host_bridge.dart';
import 'package:flutter/material.dart';

import '../../screens/app_stack/app_stack_scope.dart';
import '../../screens/app_stack/tabs/peyapay/widgets/peyapay_review_animations.dart';
import '../../screens/app_stack/tabs/peyapay/screens/peyapay_review_transfer_screen.dart';
import '../../screens/app_stack/tabs/peyapay/widgets/review_transfer_sheet.dart';

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
    final result = await Navigator.of(context).push<bool>(
      peyapayReviewTransferRoute(
        PeyapayReviewTransferScreen(
          type: PeyapayTransactionType.payment,
          amount: request.amount,
          fee: 0,
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
