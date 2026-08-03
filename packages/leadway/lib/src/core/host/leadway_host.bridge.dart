import 'package:flutter/material.dart';

/// Host-provided Mon Peya session for Leadway (phone + PIN auth).
abstract class LeadwayHostAuth {
  Future<bool> isSessionActive();
  Future<String?> getPhone();
  Future<String?> displayName();
  Future<String?> monPeyaAccessToken();
}

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

typedef LeadwayEnsureSession = Future<bool> Function(BuildContext context);


typedef LeadwayMetaSetter = Future<void> Function(String key, String value);
typedef LeadwayMetaGetter = Future<String?> Function(String key);

abstract class LeadwayMetaKeys {
  static const customerId = 'customerId';
  static const subscriptionRef = 'subscriptionRef';
  static const phone = 'phone';
}


class LeadwayHostBridge {
  LeadwayHostBridge._();

  static LeadwayHostAuth? auth;
  static LeadwayExitHandler? onExitModule;
  static LeadwayPaymentHandler? onPayment;
  static LeadwayEnsureSession? ensureSession;

  /// Branché par l'app sur [ServiceMetadataStore.set].
  static LeadwayMetaSetter? onSetMeta;

  /// Branché par l'app sur [ServiceMetadataStore.get] (+ fallbacks).
  static LeadwayMetaGetter? onGetMeta;

  static LeadwayHostAuth get requireAuth {
    final host = auth;
    if (host == null) {
      throw StateError('LeadwayHostBridge.auth not configured by Mon Peya shell.');
    }
    return host;
  }

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

  /// Opens host login / PIN when a Peya Pay payment needs an active session.
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    try {
      if (await requireAuth.isSessionActive()) return true;
    } catch (_) {
      return false;
    }
    final handler = ensureSession;
    if (handler == null) return false;
    return handler(context);
  }

  /// Phone from the active Mon Peya session (after [ensureLoggedIn]).
  static Future<String?> sessionPhone() async {
    try {
      if (!await requireAuth.isSessionActive()) return null;
      final phone = await requireAuth.getPhone();
      final trimmed = phone?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } catch (_) {
      return null;
    }
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
