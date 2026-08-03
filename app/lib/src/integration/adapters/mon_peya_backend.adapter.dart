import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:immo/immo.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/api/models/mon_peya_auth.models.dart';
import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_api.service.dart';
import 'package:app/src/core/auth/pin_auth.logger.dart';
import 'package:app/src/core/storage/auth.store.dart';

import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';

MonPeyaApiService? _monPeyaApi;

MonPeyaApiService get monPeyaApi {
  return _monPeyaApi ??= MonPeyaApiService();
}

void registerMonPeyaApi({MonPeyaApiService? api}) {
  _monPeyaApi = api ?? MonPeyaApiService();
}

Future<MonPeyaAuthSession> monPeyaLookupPhone(String phone) {
  PinAuthLogger.step('Backend lookup — ${PinAuthLogger.maskPhone(phone)}');
  return monPeyaApi.lookupPhone(phone);
}

Future<void> monPeyaSendOtp(String phone) {
  PinAuthLogger.step('Backend OTP send — ${PinAuthLogger.maskPhone(phone)}');
  return monPeyaApi.sendOtp(phone);
}

Future<MonPeyaAuthSession> monPeyaVerifyOtp({
  required String phone,
  required String code,
}) {
  return monPeyaApi.verifyOtp(phone: phone, otpCode: code);
}

Future<MonPeyaAccessDecision> monPeyaCheckAccess({
  required String moduleCode,
  String? actionCode,
}) async {
  final accessToken = await AuthStore.monPeyaAccessToken();
  return monPeyaApi.checkAccess(
    moduleCode: moduleCode,
    actionCode: actionCode,
    accessToken: accessToken,
  );
}

Future<List<MonPeyaPlan>> monPeyaListPlans({
  String? moduleCode,
  String? role,
}) {
  return monPeyaApi.listPlans(moduleCode: moduleCode, role: role);
}

Future<List<MonPeyaSubscription>> monPeyaMySubscriptions({
  String? moduleCode,
  String? role,
}) async {
  final accessToken = await AuthStore.monPeyaAccessToken();
  if (accessToken == null || accessToken.isEmpty) {
    throw MonPeyaApiException(message: 'Session requise');
  }
  return monPeyaApi.mySubscriptions(
    accessToken: accessToken,
    moduleCode: moduleCode,
    role: role,
  );
}

Future<MonPeyaSubscription> monPeyaSubscribe({
  required String planCode,
  String? moduleCode,
  String role = 'CLIENT',
}) async {
  final accessToken = await AuthStore.monPeyaAccessToken();
  if (accessToken == null || accessToken.isEmpty) {
    throw MonPeyaApiException(message: 'Session requise');
  }
  return monPeyaApi.subscribe(
    accessToken: accessToken,
    planCode: planCode,
    moduleCode: moduleCode,
    role: role,
  );
}

Future<MonPeyaAuthUser> monPeyaMe() async {
  final accessToken = await AuthStore.monPeyaAccessToken();
  if (accessToken == null || accessToken.isEmpty) {
    throw MonPeyaApiException(message: 'Session requise');
  }
  return monPeyaApi.me(accessToken: accessToken);
}

Future<MonPeyaSubscriptionRequest> monPeyaRequestDeplafonnement() async {
  final accessToken = await AuthStore.monPeyaAccessToken();
  if (accessToken == null || accessToken.isEmpty) {
    throw MonPeyaApiException(message: 'Session requise');
  }
  return monPeyaApi.requestDeplafonnement(accessToken: accessToken);
}

Future<List<MonPeyaSubscriptionRequest>> monPeyaMySubscriptionRequests() async {
  final accessToken = await AuthStore.monPeyaAccessToken();
  if (accessToken == null || accessToken.isEmpty) {
    throw MonPeyaApiException(message: 'Session requise');
  }
  return monPeyaApi.mySubscriptionRequests(accessToken: accessToken);
}

Future<void> monPeyaLogoutSession() async {
  final token = await AuthStore.monPeyaAccessToken();
  if (token == null || token.isEmpty) return;
  try {
    await monPeyaApi.logout(accessToken: token);
  } on MonPeyaApiException {
    // Best-effort — clear local session anyway.
  }
}

Future<void> _persistMonPeyaSession(MonPeyaAuthSession session) async {
  await AuthStore.setMonPeyaAccessToken(session.accessToken);
  await AuthStore.setMonPeyaRefreshToken(session.refreshToken);

  final user = session.user;
  if (user != null) {
    await AuthStore.setMonPeyaUserId(user.userId);
    await AuthStore.setCodeClient(user.codeClient);
    await AuthStore.setPeyaAccountProfile(
      isPeyaClient: user.isPeyaClient,
      isPeyapayMerchant: user.isPeyapayMerchant,
    );
  }
}

/// Persists backend tokens + PeyaPay client preview after OTP verify.
Future<void> monPeyaPersistAuthSession(MonPeyaAuthSession session) async {
  await _persistMonPeyaSession(session);
  _seedClientStateFromSession(session);
}

void _seedClientStateFromSession(MonPeyaAuthSession session) {
  final user = session.user;
  if (user == null) return;
  final api = PeyapayHostBridge.api;
  if (api == null) return;

  final name = user.nomClient?.trim().isNotEmpty == true
      ? user.nomClient
      : user.displayName;
  final account = user.numerocomptecomplet?.trim().isNotEmpty == true
      ? user.numerocomptecomplet
      : user.accountId;

  api.setClientState(
    PeyapayClientState(
      accountId: account,
      codePaysResidence: user.codePaysResidence ?? 'CI',
      etatClient: PeyapayClientEtat.customer,
      gsmPrincipale: user.phone,
      nomClient: name,
    ),
  );
}

void _syncPeyapayWalletInBackground(String phone, String pin) {
  unawaited(() async {
    try {
      await syncPeyapayApiSession(phone: phone, pin: pin);
      notifyMonPeyaSessionChanged();
    } catch (_) {}
  }());
}

void _syncImmoSessionInBackground(String phone, String pin) {
  unawaited(() async {
    try {
      // Login, lookup, or auto-create Mr Immo rental user after Mon Peya auth.
      final client = ImmoApiClient();
      final result = await ImmoAuthService(client: client).ensureSession(
        apiClient: client,
      );
      if (kDebugMode) {
        debugPrint(
          result.ok
              ? '[ImmoAuth] background sync OK userId=${result.userId}'
              : '[ImmoAuth] background sync failed: ${result.error}',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ImmoAuth] background sync error: $e');
    }
  }());
}

/// Login via monpeya_backend (auth only), then hydrate PeyaPay wallet directly on Peya API.
Future<MonPeyaAuthSession> authenticateMonPeyaSession({
  required String phone,
  required String pin,
}) async {
  PinAuthLogger.step(
    'Backend login — ${PinAuthLogger.maskPhone(phone)}, PIN ${PinAuthLogger.maskPinLength(pin.trim().length)}',
  );

  final session = await monPeyaApi.login(phone: phone, pin: pin);
  await _persistMonPeyaSession(session);
  _seedClientStateFromSession(session);
  PinAuthLogger.success('Session Mon Peya backend OK');

  // Await profile + balance so home/wallet show data immediately.
  try {
    await syncPeyapayApiSession(phone: phone, pin: pin);
  } catch (_) {
    _syncPeyapayWalletInBackground(phone, pin);
  }
  _syncImmoSessionInBackground(phone, pin);

  return session;
}

Future<MonPeyaAuthSession?> refreshMonPeyaSessionIfNeeded() async {
  final refreshToken = await AuthStore.monPeyaRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) return null;

  try {
    final session = await monPeyaApi.refresh(refreshToken: refreshToken);
    await _persistMonPeyaSession(session);
    _seedClientStateFromSession(session);
    return session;
  } on MonPeyaApiException {
    return null;
  }
}
