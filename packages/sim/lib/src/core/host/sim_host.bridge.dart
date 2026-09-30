import 'package:flutter/material.dart';

abstract class SimHostAuth {
  Future<bool> isSessionActive();
  Future<String?> getPhone();
  Future<String?> displayName();
}

typedef SimExitHandler = void Function(BuildContext context);

class SimPaymentRequest {
  const SimPaymentRequest({
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

typedef SimPaymentHandler = Future<bool> Function(
  BuildContext context,
  SimPaymentRequest request,
);

typedef SimEnsureSession = Future<bool> Function(BuildContext context);
typedef SimMetaSetter = Future<void> Function(String key, String value);
typedef SimMetaGetter = Future<String?> Function(String key);

abstract class SimMetaKeys {
  static const souscriptionId = 'souscriptionId';
  static const phone = 'phone';
  static const paymentReference = 'paymentReference';
}

class SimHostBridge {
  SimHostBridge._();

  static SimHostAuth? auth;
  static SimExitHandler? onExitModule;
  static SimPaymentHandler? onPayment;
  static SimEnsureSession? ensureSession;
  static SimMetaSetter? onSetMeta;
  static SimMetaGetter? onGetMeta;

  static SimHostAuth get requireAuth {
    final host = auth;
    if (host == null) {
      throw StateError('SimHostBridge.auth not configured by Mon Peya shell.');
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
    SimPaymentRequest request,
  ) async {
    final handler = onPayment;
    if (handler == null) {
      throw StateError('SimHostBridge.onPayment not configured by Mon Peya shell.');
    }
    return handler(context, request);
  }

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

  static Future<void> setMeta(String key, String value) async {
    final handler = onSetMeta;
    if (handler == null) return;
    await handler(key, value);
  }

  static Future<String?> getMeta(String key) async {
    final handler = onGetMeta;
    if (handler == null) return null;
    return handler(key);
  }
}
