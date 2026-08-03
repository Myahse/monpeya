import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Payment request forwarded to Mon Peya Peya Pay.
class BilletteriePaymentRequest {
  const BilletteriePaymentRequest({
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

typedef BilletteriePaymentHandler = Future<bool> Function(
  BuildContext context,
  BilletteriePaymentRequest request,
);

typedef BilletterieExitHandler = void Function(BuildContext context);

typedef BilletterieClientResolver = Future<BilletterieClientIdentity?> Function();

typedef BilletterieModuleBackHandler = bool Function();

/// Whether the signed-in PeyaPay account is already a merchant.
typedef BilletterieMerchantResolver = Future<bool> Function();

/// Whether the signed-in account has a PeyaPay **client** wallet (can buy tickets).
typedef BilletterieClientWalletResolver = Future<bool> Function();

/// Merchant-only PeyaPay (no client wallet) — hide client-side service UI.
typedef BilletterieMerchantOnlyResolver = Future<bool> Function();

/// Mon Peya subscription role for this account (`CLIENT` vs `FOURNISSEUR`).
typedef BilletterieServiceRoleResolver = Future<String> Function();

/// Gate before purchase: register / OTP if needed, then service subscription.
typedef BilletterieEnsureCanPurchase = Future<bool> Function(
  BuildContext context, {
  required String moduleKey,
});

/// Prompt host login / PIN (guest → session).
typedef BilletterieEnsureSession = Future<bool> Function(BuildContext context);

/// Loads a host-app asset (e.g. Mon Peya logo) for PDF export.
typedef BilletterieHostAssetLoader = Future<Uint8List?> Function(String path);

/// Peya identity resolved by the Mon Peya shell for ticketing API calls.
class BilletterieClientIdentity {
  const BilletterieClientIdentity({
    required this.codeClient,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.countryCode,
  });

  final String codeClient;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? countryCode;

  String get resolvedDisplayName {
    final full = displayName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final parts = [
      if (firstName?.trim().isNotEmpty == true) firstName!.trim(),
      if (lastName?.trim().isNotEmpty == true) lastName!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(' ');
    return 'Client PeyaPay';
  }
}

/// Registered by Mon Peya before opening Billetterie.
class BilletterieHostBridge {
  BilletterieHostBridge._();

  /// Preferred host logo for PDF (tight crop; Photoroom has large transparent padding).
  static const monPeyaLogoAssetPath = 'assets/logo/app-icons/mon peya.png';

  static BilletteriePaymentHandler? onPayment;
  static BilletterieExitHandler? onExitModule;
  static BilletterieClientResolver? resolveClient;
  static BilletterieModuleBackHandler? onModuleBack;
  static BilletterieMerchantResolver? resolveIsMerchant;
  static BilletterieClientWalletResolver? resolveHasClientWallet;
  static BilletterieMerchantOnlyResolver? resolveIsMerchantOnly;
  static BilletterieServiceRoleResolver? resolveServiceSubscriptionRole;
  static BilletterieEnsureCanPurchase? ensureCanPurchase;
  static BilletterieEnsureSession? ensureSession;
  static BilletterieHostAssetLoader? loadHostAsset;

  /// Host session listenable (Mon Peya) — modules reload guest/name on change.
  static Listenable? sessionChanges;

  /// Guest display name when the host session is inactive.
  static const guestDisplayName = 'Utilisateur';

  static bool tryHandleModuleBack() => onModuleBack?.call() ?? false;

  static Future<bool> isPeyapayMerchant() async {
    final resolver = resolveIsMerchant;
    if (resolver == null) return false;
    try {
      return await resolver();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasClientWallet() async {
    final resolver = resolveHasClientWallet;
    if (resolver == null) return true;
    try {
      return await resolver();
    } catch (_) {
      return true;
    }
  }

  static Future<bool> isMerchantOnly() async {
    final resolver = resolveIsMerchantOnly;
    if (resolver != null) {
      try {
        return await resolver();
      } catch (_) {
        return false;
      }
    }
    final merchant = await isPeyapayMerchant();
    if (!merchant) return false;
    return !(await hasClientWallet());
  }

  static Future<String> serviceSubscriptionRole() async {
    final resolver = resolveServiceSubscriptionRole;
    if (resolver != null) {
      try {
        final role = await resolver();
        if (role.trim().isNotEmpty) return role.trim().toUpperCase();
      } catch (_) {}
    }
    if (await isMerchantOnly()) return 'FOURNISSEUR';
    return 'CLIENT';
  }

  static Future<BilletterieClientIdentity> requireClient() async {
    final resolver = resolveClient;
    if (resolver == null) {
      throw StateError('BilletterieHostBridge.resolveClient not configured by Mon Peya shell.');
    }
    final identity = await resolver();
    if (identity == null || identity.codeClient.trim().isEmpty) {
      throw StateError('Identité Peya indisponible pour la billetterie.');
    }
    return identity;
  }

  /// Soft resolve for guest-safe screens (owned tickets, dashboards).
  /// Returns `null` when the host session is inactive.
  static Future<BilletterieClientIdentity?> resolveClientOrNull() async {
    final resolver = resolveClient;
    if (resolver == null) return null;
    try {
      return await resolver();
    } catch (_) {
      return null;
    }
  }

  /// Opens host login / PIN. Returns `true` when a session is active afterward.
  static Future<bool> promptLogin(BuildContext context) async {
    final handler = ensureSession;
    if (handler == null) return false;
    return handler(context);
  }

  /// True when no Peya session is active (browse-only).
  static Future<bool> isGuest() async =>
      await resolveClientOrNull() == null;

  /// Login gate for purchase / personal data — does not check subscription.
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (await resolveClientOrNull() != null) return true;
    return promptLogin(context);
  }

  /// Auth + subscription gate before ticket payment. Host implements the checks.
  static Future<bool> ensureReadyToPurchase(
    BuildContext context, {
    String moduleKey = 'billetterie-transport',
  }) async {
    final handler = ensureCanPurchase;
    if (handler == null) return true;
    return handler(context, moduleKey: moduleKey);
  }

  /// Leave Billetterie and return to the Mon Peya shell (home tabs).
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
    BilletteriePaymentRequest request,
  ) async {
    if (request.amount <= 0) return true;
    final handler = onPayment;
    if (handler == null) {
      throw StateError('BilletterieHostBridge.onPayment not configured by Mon Peya shell.');
    }
    return handler(context, request);
  }
}
