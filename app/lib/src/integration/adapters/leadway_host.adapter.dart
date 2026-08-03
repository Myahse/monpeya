import 'package:flutter/material.dart';
import 'package:leadway/leadway.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/peyapay/peyapay_profile.util.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/storage/service_metadata.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

class MonPeyaLeadwayHostAuth implements LeadwayHostAuth {
  const MonPeyaLeadwayHostAuth();

  @override
  Future<bool> isSessionActive() async => MonPeyaSession.instance.isSessionActive;

  @override
  Future<String?> getPhone() => AuthStore.getPhone();

  @override
  Future<String?> displayName() async => PeyapayProfileDisplay.clientName();

  @override
  Future<String?> monPeyaAccessToken() => AuthStore.monPeyaAccessToken();
}

/// Connecte Mon Peya à Leadway : navigation, paiement, **métadonnées app**.
class MonPeyaLeadwayHostAdapter {
  MonPeyaLeadwayHostAdapter._();

  static const _service = ServiceMetaNames.leadway;

  static void register() {
    LeadwayHostBridge.auth = const MonPeyaLeadwayHostAuth();
    LeadwayHostBridge.onExitModule = _exitToMonPeyaHome;
    LeadwayHostBridge.onPayment = _handlePayment;
    LeadwayHostBridge.onSetMeta = setLeadwayMeta;
    LeadwayHostBridge.onGetMeta = getLeadwayMeta;
  }

  /// Écriture métadonnée Leadway — implémentation **app**.
  static Future<void> setLeadwayMeta(String key, String value) {
    return ServiceMetadataStore.set(_service, key, value);
  }

  /// Lecture métadonnée Leadway — implémentation **app**.
  ///
  /// - `customerId` : lu ou **généré** puis persisté
  /// - `phone` : meta Leadway ou téléphone session Mon Peya
  /// - autres clés : lecture seule (ex. `subscriptionRef`)
  static Future<String?> getLeadwayMeta(String key) async {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return null;

    if (normalizedKey == ServiceMetaKeys.customerId || normalizedKey == LeadwayMetaKeys.customerId) {
      return ensureLeadwayCustomerId();
    }

    // subscriptionRef : uniquement la valeur renvoyée par l'API souscription (pas de génération).
    final stored = await ServiceMetadataStore.get(_service, normalizedKey);
    if (stored != null && stored.isNotEmpty) return stored;

    if (normalizedKey == ServiceMetaKeys.phone || normalizedKey == LeadwayMetaKeys.phone) {
      return _sessionPhoneAndPersist();
    }

    return null;
  }

  /// customerId stable : réutilise la meta, sinon génère et enregistre.
  static Future<String> ensureLeadwayCustomerId() async {
    final existing = await ServiceMetadataStore.get(_service, ServiceMetaKeys.customerId);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final generated = 'LW-CUST-${DateTime.now().millisecondsSinceEpoch}';
    await ServiceMetadataStore.set(_service, ServiceMetaKeys.customerId, generated);
    return generated;
  }

  static Future<String?> _sessionPhoneAndPersist() async {
    final phone = await AuthStore.getPhone();
    final trimmed = phone?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    await ServiceMetadataStore.set(_service, ServiceMetaKeys.phone, trimmed);
    return trimmed;
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
