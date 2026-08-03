import 'package:billetterie/billetterie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/subscriptions/presentation/screens/service_abonnement.screen.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

/// Connects Mon Peya Peya Pay to the independent Billetterie package.
class MonPeyaBilletterieHostAdapter {
  MonPeyaBilletterieHostAdapter._();

  /// Backend module code (catalog) — not the Flutter transport key.
  static const backendModuleCode = 'billetterie';
  static const checkoutAction = 'ticket.checkout';

  static void register() {
    BilletterieHostBridge.onPayment = _handlePayment;
    BilletterieHostBridge.onExitModule = _exitToMonPeyaHome;
    BilletterieHostBridge.resolveClient = _resolveClient;
    BilletterieHostBridge.resolveIsMerchant = _resolveIsMerchant;
    BilletterieHostBridge.resolveHasClientWallet = _resolveHasClientWallet;
    BilletterieHostBridge.resolveIsMerchantOnly = _resolveIsMerchantOnly;
    BilletterieHostBridge.resolveServiceSubscriptionRole =
        AuthStore.serviceSubscriptionRole;
    BilletterieHostBridge.ensureCanPurchase = _ensureCanPurchase;
    BilletterieHostBridge.ensureSession = ModuleAuth.ensureRegistered;
    BilletterieHostBridge.sessionChanges = MonPeyaSession.instance;
    BilletterieHostBridge.loadHostAsset = (path) async {
      try {
        final data = await rootBundle.load(path);
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    };
  }

  static Future<bool> _resolveIsMerchant() async {
    if (await AuthStore.isPeyapayMerchantFlag() == true) return true;
    final state = PeyapayHostBridge.api?.clientState;
    if (state == null) return false;
    return PeyapayAccountProfile.resolve(sessionState: state).hasMerchantWallet;
  }

  static Future<bool> _resolveHasClientWallet() => AuthStore.hasClientWallet();

  static Future<bool> _resolveIsMerchantOnly() => AuthStore.isMerchantOnly();

  /// Payment gate:
  /// 1) Register / OTP / PIN if needed
  /// 2) Check active Billetterie subscription
  /// 3) If missing → open abonnement screen (single vs grouped)
  static Future<bool> _ensureCanPurchase(
    BuildContext context, {
    required String moduleKey,
  }) async {
    if (!context.mounted) return false;

    if (await AuthStore.isFournisseurOnly()) {
      if (!context.mounted) return false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Compte fournisseur'),
          content: const Text(
            'Ce numéro est un compte fournisseur PeyaPay sans portefeuille client. '
            'Utilisez l’espace professionnel du service et abonnez-vous en tant que fournisseur.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return false;
    }

    final registered = await ModuleAuth.ensureRegistered(context);
    if (!registered || !context.mounted) return false;

    final hasAccess = await _hasActiveSubscription();
    if (hasAccess) return true;
    if (!context.mounted) return false;

    final wantsSubscribe = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Abonnement requis'),
          content: const Text(
            'Pour payer un billet, choisissez une formule d’abonnement '
            'Billetterie (individuel ou groupé).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Voir les formules'),
            ),
          ],
        );
      },
    );
    if (wantsSubscribe != true || !context.mounted) return false;

    final subscriptionRole = await AuthStore.serviceSubscriptionRole();
    final subscribed = await Navigator.of(context, rootNavigator: true)
        .push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ServiceAbonnementScreen(
          moduleCode: backendModuleCode,
          role: subscriptionRole,
          serviceTitle: 'Billetterie',
        ),
      ),
    );
    if (subscribed != true) return false;

    // Re-check after subscribe (backend + local fallback).
    return _hasActiveSubscription();
  }

  static Future<bool> _hasActiveSubscription() async {
    final role = await AuthStore.serviceSubscriptionRole();
    try {
      final decision = await monPeyaCheckAccess(
        moduleCode: backendModuleCode,
        actionCode: checkoutAction,
      );
      if (decision.allowed || decision.hasActiveSubscription == true) {
        return true;
      }
      final subs = await monPeyaMySubscriptions(
        moduleCode: backendModuleCode,
        role: role,
      );
      if (subs.any((s) => s.isActive)) return true;
    } catch (_) {
      if (role == 'FOURNISSEUR') {
        final profile = await TransportProfileStore().load();
        return profile.canUseAsConductor;
      }
      final profile = await TransportProfileStore().load();
      return profile.canUseAsClient;
    }
    return false;
  }

  static Future<BilletterieClientIdentity?> _resolveClient() async {
    // Guests may browse catalogs; personal tickets need login or a live token.
    if (!await ModuleAuth.hasActiveSessionOrToken()) return null;

    final phone = await AuthStore.getPhone();
    if (phone == null || phone.trim().isEmpty) return null;

    final api = PeyapayHostBridge.api;
    final state = api?.clientState;

    String? codeClient = (await AuthStore.codeClient())?.trim();
    String? displayName = state?.nomClient?.trim();
    String? email = state?.email?.trim();
    String? gsm = state?.gsmPrincipale?.trim();
    final country = state?.codePaysResidence.trim().isNotEmpty == true
        ? state!.codePaysResidence.trim()
        : 'CI';

    if (state?.codeClient?.trim().isNotEmpty == true) {
      codeClient = state!.codeClient!.trim();
    }

    if ((displayName == null || displayName.isEmpty) ||
        (codeClient == null || codeClient.isEmpty)) {
      if (api != null) {
        try {
          await api.ensureBearerToken();
          final search = await api.searchGsm(phone: phone);
          final profile = search.firstProfile;
          codeClient ??= profile?.codeClient?.trim();
          displayName ??= profile?.nomClient?.trim();
          gsm ??= profile?.gsmPrincipale?.trim();
        } catch (_) {}
      }
    }

    if (codeClient == null || codeClient.isEmpty) return null;

    final nameParts = _splitDisplayName(displayName);
    final phoneParts = _splitPhone(gsm ?? phone);

    return BilletterieClientIdentity(
      codeClient: codeClient,
      displayName: displayName,
      firstName: nameParts.$1,
      lastName: nameParts.$2,
      phone: phoneParts.$2.isNotEmpty ? phoneParts.$2 : phone,
      email: email,
      countryCode: phoneParts.$1.isNotEmpty
          ? phoneParts.$1
          : _dialCodeForCountry(country),
    );
  }

  static (String?, String?) _splitDisplayName(String? raw) {
    final name = raw?.trim() ?? '';
    if (name.isEmpty) return (null, null);
    final bits = name.split(RegExp(r'\s+'));
    if (bits.length == 1) return (bits.first, null);
    return (bits.first, bits.sublist(1).join(' '));
  }

  static (String, String) _splitPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+225')) {
      return ('+225', digits.substring(4));
    }
    if (digits.startsWith('225') && digits.length > 3) {
      return ('+225', digits.substring(3));
    }
    if (digits.startsWith('+')) {
      final code = digits.length >= 4 ? digits.substring(0, 4) : digits;
      final rest = digits.length > 4 ? digits.substring(4) : '';
      return (code, rest);
    }
    return ('+225', digits);
  }

  static String _dialCodeForCountry(String codePays) {
    switch (codePays.toUpperCase()) {
      case 'CI':
        return '+225';
      case 'SN':
        return '+221';
      case 'BF':
        return '+226';
      case 'ML':
        return '+223';
      default:
        return '+225';
    }
  }

  static void _exitToMonPeyaHome(BuildContext context) {
    AppStackScope.maybeOf(context)?.exitModule();
  }

  static Future<bool> _handlePayment(
    BuildContext context,
    BilletteriePaymentRequest request,
  ) async {
    if (!context.mounted) return false;

    // Login + subscription were already checked in the billet pay flow.
    final sender = await peyapayPrimarySender() ??
        const PeyapaySender(
          title: 'Compte principal',
          subtitle: 'PeyaPay',
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF006D56),
        );
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
