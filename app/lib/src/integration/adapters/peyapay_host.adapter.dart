import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/auth/pin_auth.logger.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/widgets/nteri_news_carousel.widget.dart';


class MonPeyaPeyapayHostAdapter implements PeyapayHostAuth {
  const MonPeyaPeyapayHostAdapter();

  static void register() {
    PeyapayHostBridge.api = PeyapayApiService();
    PeyapayHostBridge.auth = const MonPeyaPeyapayHostAdapter();
    PeyapayHostBridge.sessionChanges = MonPeyaSession.instance;
    PeyapayHostBridge.openRoute = (routeName) async {
      await rootNavKey.currentState?.pushNamed(routeName);
    };
    PeyapayHostBridge.buildNewsCarousel = (context, {height = 200}) {
      return NteriNewsCarousel(height: height);
    };
    PeyapayHostBridge.ensureRegisteredForTransaction = (BuildContext context) {
      return ModuleAuth.ensureRegistered(context);
    };
    PeyapayHostBridge.onSessionChanged = notifyMonPeyaSessionChanged;
    PeyapayHostBridge.loadHostAsset = (path) async {
      try {
        final data = await rootBundle.load(path);
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    };
  }

  @override
  Future<bool> isSessionActive() => ModuleAuth.hasActiveSessionOrToken();

  @override
  Future<bool> hasAccount() => AuthStore.hasAccount();

  @override
  Future<String?> getPhone() => AuthStore.getPhone();

  /// PeyaPay client JWT for wallet API calls (not Mon Peya backend token).
  @override
  Future<String?> authToken() => AuthStore.authToken();
}

void notifyMonPeyaSessionChanged() => MonPeyaSession.instance.notifySessionChanged();

void activateMonPeyaSession() {
  MonPeyaSession.instance.activateSession();
}

void endMonPeyaSession() {
  MonPeyaSession.instance.endSession();
  final api = PeyapayHostBridge.api;
  api?.setClientState(null);
  api?.setWalletBalance(null);
  api?.setBearerToken(null);
}

PeyapayApiService _requirePeyapayApi() {
  final api = PeyapayHostBridge.api;
  if (api == null) {
    throw PeyapayApiException(message: 'API PeyaPay non initialisée');
  }
  return api;
}

Future<PeyapayGsmSearchResult> peyapaySearchPhone(String phone) {
  return _requirePeyapayApi().searchGsm(phone: phone);
}

Future<void> peyapaySendOtp(String phone) {
  return _requirePeyapayApi().sendClientOtp(
    phone: phone,
    includeDeviceInfo: true,
  );
}

Future<void> peyapayVerifyOtp({
  required String phone,
  required String code,
}) {
  return _requirePeyapayApi().verifyOtpCode(phone: phone, code: code);
}

Future<PeyapayPinVerificationResult> peyapayVerifyClientPin({
  required String phone,
  required String pin,
}) {
  return _requirePeyapayApi().verifyClientPin(phone: phone, pin: pin);
}

Future<PeyapayWalletBalance> peyapayFetchWalletBalance(String phone) {
  return _requirePeyapayApi().fetchWalletBalance(phone: phone);
}

/// Ensures a PeyaPay client JWT is on the API service (direct Peya, not backend).
Future<void> peyapayEnsureBearerReady({bool preferAppToken = false}) async {
  final api = _requirePeyapayApi();
  await api.hydrateBearerFrom(AuthStore.authToken, preferAppToken: preferAppToken);

  final token = await AuthStore.authToken();
  if (token != null && token.isNotEmpty) return;

  final phone = await AuthStore.getPhone();
  if (phone == null || phone.trim().isEmpty) return;

  final pin = await AuthStore.getPinForPhone(phone);
  if (pin == null || pin.trim().length < 4) return;

  await authenticatePeyapaySession(phone: phone, pin: pin);
}

Future<PeyapayClientTransferResult> peyapayTransferToClient({
  required String recipientPhone,
  required int amountReceived,
  int fee = 0,
}) async {
  final phone = await AuthStore.getPhone();
  if (phone == null || phone.trim().isEmpty) {
    throw PeyapayApiException(message: 'Numéro expéditeur indisponible');
  }
  await peyapayEnsureBearerReady();
  return _requirePeyapayApi().transferToClient(
    senderPhone: phone,
    recipientPhone: recipientPhone,
    amountReceived: amountReceived,
    fee: fee,
    ensureToken: false,
  );
}

/// Direct PeyaPay wallet session: JWT + etatclient + balance (not monpeya_backend).
Future<PeyapayClientState> authenticatePeyapaySession({
  required String phone,
  required String pin,
}) async {
  final api = _requirePeyapayApi();
  PinAuthLogger.step(
    'PeyaPay /authclient/token — ${PinAuthLogger.maskPhone(phone)}',
  );

  final auth = await api.loginClientWallet(phone: phone, pin: pin);
  await AuthStore.setAuthToken(auth.token);
  api.setBearerToken(auth.token);
  PinAuthLogger.success('JWT PeyaPay client OK');

  PinAuthLogger.step('API /wClients/etatclient');
  final state = await api.fetchClientState(phone: phone);
  PinAuthLogger.success(
    'Profil chargé${state.nomClient != null ? ' — ${state.nomClient}' : ''}',
  );

  PeyapayGsmSearchResult? gsmSearch;
  try {
    gsmSearch = await api.searchGsm(phone: phone, ensureToken: false);
  } catch (_) {}

  final profile = PeyapayAccountProfile.resolve(
    sessionState: state,
    gsmSearch: gsmSearch,
  );
  if (profile.hasClientWallet || profile.hasMerchantWallet) {
    await AuthStore.setPeyaAccountProfile(
      isPeyaClient: profile.hasClientWallet,
      isPeyapayMerchant: profile.hasMerchantWallet,
    );
  }

  try {
    PinAuthLogger.step('API /wClients/solde');
    final balance = await api.refreshWalletBalance(
      phone: phone,
      pin: pin,
      ensureToken: false,
    );
    PinAuthLogger.success(
      'Solde chargé${balance.solde != null ? ' — ${balance.solde} XOF' : ''}',
    );
  } on PeyapayApiException catch (e) {
    PinAuthLogger.failure('Solde PeyaPay', e);
  }

  return state;
}

/// Loads PeyaPay wallet state after Mon Peya backend login (wallet stays on Peya API).
Future<PeyapayClientState?> syncPeyapayApiSession({
  required String phone,
  required String pin,
}) async {
  try {
    return await authenticatePeyapaySession(
      phone: phone,
      pin: pin,
    );
  } on PeyapayApiException {
    return null;
  } catch (_) {
    return null;
  }
}
