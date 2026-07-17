import 'package:flutter/material.dart';

typedef LeadwayExitHandler = void Function(BuildContext context);

class LeadwayPaymentRequest {
  const LeadwayPaymentRequest({
    required this.amount,
    required this.recipientName,
    required this.label,
    this.reference,
  });

  final int amount;
  final String recipientName;
  final String label;
  final String? reference;
}

typedef LeadwayPaymentHandler = Future<bool> Function(
  BuildContext context,
  LeadwayPaymentRequest request,
);

/// Hooks injectés par Mon Peya (`ServiceMetadataStore` vit dans l'app).
typedef LeadwayMetaSetter = Future<void> Function(String key, String value);
typedef LeadwayMetaGetter = Future<String?> Function(String key);

/// Clés métier Leadway — le stockage JSON est côté app uniquement.
abstract class LeadwayMetaKeys {
  static const customerId = 'customerId';
  static const subscriptionRef = 'subscriptionRef';
  static const phone = 'phone';
}

/// Bridge Mon Peya ↔ Leadway.
///
/// Les métadonnées ne sont **pas** stockées ici : [setMeta] / [getMeta]
/// appellent uniquement les handlers enregistrés par l'app
/// (`ServiceMetadataStore.set/get` avec le service `leadway`).
class LeadwayHostBridge {
  LeadwayHostBridge._();

  static LeadwayExitHandler? onExitModule;
  static LeadwayPaymentHandler? onPayment;

  /// Branché par l'app sur [ServiceMetadataStore.set].
  static LeadwayMetaSetter? onSetMeta;

  /// Branché par l'app sur [ServiceMetadataStore.get] (+ fallbacks).
  static LeadwayMetaGetter? onGetMeta;

  static void exitModule(BuildContext context) {
    final handler = onExitModule;
    if (handler != null) {
      handler(context);
      return;
    }
    Navigator.of(context).maybePop();
  }

  static Future<bool> requestPayment(
    BuildContext context,
    LeadwayPaymentRequest request,
  ) async {
    final handler = onPayment;
    if (handler == null) {
      throw StateError('LeadwayHostBridge.onPayment not configured by Mon Peya shell.');
    }
    return handler(context, request);
  }

  /// Appelle la fonction app : `ServiceMetadataStore.set('leadway', key, value)`.
  static Future<void> setMeta(String key, String value) async {
    final handler = onSetMeta;
    if (handler == null) {
      assert(() {
        debugPrint('[Leadway] setMeta ignored — host app not registered.');
        return true;
      }());
      return;
    }
    await handler(key, value);
  }

  /// Appelle la fonction app : `ServiceMetadataStore.get('leadway', key)`.
  static Future<String?> getMeta(String key) async {
    final handler = onGetMeta;
    if (handler == null) {
      assert(() {
        debugPrint('[Leadway] getMeta ignored — host app not registered.');
        return true;
      }());
      return null;
    }
    return handler(key);
  }
}
