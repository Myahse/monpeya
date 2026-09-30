import 'package:flutter/material.dart';
import 'package:sim/sim.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/peyapay/peyapay_profile.util.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/storage/service_metadata.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

class MonPeyaSimHostAuth implements SimHostAuth {
  const MonPeyaSimHostAuth();

  @override
  Future<bool> isSessionActive() => ModuleAuth.hasActiveSessionOrToken();

  @override
  Future<String?> getPhone() => AuthStore.getPhone();

  @override
  Future<String?> displayName() async => PeyapayProfileDisplay.clientName();
}

class MonPeyaSimHostAdapter {
  MonPeyaSimHostAdapter._();

  static const _service = ServiceMetaNames.sim;

  static void register() {
    SimHostBridge.auth = const MonPeyaSimHostAuth();
    SimHostBridge.onExitModule = _exitToMonPeyaHome;
    SimHostBridge.onPayment = _handlePayment;
    SimHostBridge.ensureSession = ModuleAuth.ensureRegistered;
    SimHostBridge.onSetMeta = (key, value) => ServiceMetadataStore.set(_service, key, value);
    SimHostBridge.onGetMeta = (key) => ServiceMetadataStore.get(_service, key);
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
    SimPaymentRequest request,
  ) async {
    if (!context.mounted) return false;
    final ok = await ModuleAuth.ensureRegistered(context);
    if (!ok || !context.mounted) return false;

    final sender = await peyapayPrimarySender();
    if (!context.mounted) return false;

    final rootNav = rootNavKey.currentState;
    if (rootNav == null) return false;

    final result = await rootNav.push<bool>(
      peyapayReviewTransferRoute(
        PeyapayReviewTransferScreen(
          type: PeyapayTransactionType.payment,
          amount: request.amount,
          fee: 0,
          sender: sender,
          recipient: PeyapayRecipient(
            name: request.recipientName,
            reference: request.reference ?? request.label,
            icon: Icons.shield_outlined,
            color: SimBrand.primary,
          ),
        ),
      ),
    );
    return result == true;
  }
}
