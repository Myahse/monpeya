import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:peyapay/peyapay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/config/mon_peya_env.dart';
import 'package:app/src/core/auth/pin_auth.logger.dart';
import 'package:app/src/core/storage/constants/prefs.keys.dart';

class AuthStore {
  AuthStore._();

  static const _defaultCountryCode = '+225';
  static const _secureStorage = FlutterSecureStorage();

  static String _pinKey(String phone) => 'wallet_pin:$phone';

  static bool get _forceGuest => kDebugMode && MonPeyaEnv.forceGuestMode;

  static String _normalizePhone(String phone) {
    final compact = phone.trim().replaceAll(' ', '');
    if (compact.startsWith('+')) return compact;

    final digits = compact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return '$_defaultCountryCode$digits';
    }
    return compact;
  }

  static bool _isPlainPin(String value) {
    final trimmed = value.trim();
    return RegExp(r'^\d{4,8}$').hasMatch(trimmed);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.phoneNumber);
  }

  static Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.phoneNumber, phone);
  }

  static Future<bool> hasPinForPhone(String phone) async {
    final pin = await getPinForPhone(phone);
    return pin != null && pin.isNotEmpty;
  }

  /// Plain PIN .
  static Future<String?> getPinForPhone(String phone) async {
    final normalized = _normalizePhone(phone);
    PinAuthLogger.step('Lecture PIN local pour ${PinAuthLogger.maskPhone(normalized)}');

    final securePin = await _secureStorage.read(key: _pinKey(normalized));
    if (securePin != null && securePin.isNotEmpty) {
      PinAuthLogger.success('PIN local ${PinAuthLogger.maskPinLength(securePin.length)}');
      return securePin;
    }

    return _migrateLegacyPin(normalized);
  }

  static Future<String?> _migrateLegacyPin(String normalizedPhone) async {
    final prefs = await SharedPreferences.getInstance();
    final legacyKey = 'pin:$normalizedPhone';
    final stored = prefs.getString(legacyKey);
    if (stored == null || stored.isEmpty) {
      PinAuthLogger.step('Aucun PIN stocké pour ce numéro');
      return null;
    }

    PinAuthLogger.step('Migration PIN legacy depuis SharedPreferences');
    try {
      final pin = _isPlainPin(stored)
          ? stored
          : await PeyapayCryptoService().decryptString(stored) ?? stored;
      if (!_isPlainPin(pin)) {
        PinAuthLogger.failure('Migration PIN legacy — valeur illisible');
        return null;
      }
      await _writePin(normalizedPhone, pin);
      await prefs.remove(legacyKey);
      PinAuthLogger.success('PIN migré vers stockage sécurisé');
      return pin;
    } catch (e) {
      PinAuthLogger.failure('Migration PIN legacy', e);
      return null;
    }
  }

  static Future<void> setPinForPhone(String phone, String pin) async {
    PinAuthLogger.step(
      'Enregistrement PIN local ${PinAuthLogger.maskPinLength(pin.length)} pour ${PinAuthLogger.maskPhone(phone)}',
    );
    await _writePin(_normalizePhone(phone), pin.trim());
    PinAuthLogger.success('PIN enregistré (stockage sécurisé, clair au repos — marchand_dart)');
  }

  static Future<void> _writePin(String normalizedPhone, String pin) async {
    await _secureStorage.write(key: _pinKey(normalizedPhone), value: pin);
  }

  static Future<bool> isRegistered() async {
    if (_forceGuest) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefsKeys.isRegistered) ?? false;
  }

  /// Account exists on device.
  static Future<bool> hasAccount() async {
    if (_forceGuest) return false;
    if (!await isRegistered()) return false;
    final phone = await getPhone();
    if (phone == null || phone.trim().isEmpty) return false;
    return hasPinForPhone(phone);
  }

  /// Ends the current session.
  static Future<void> endSession() async {
    await setAuthToken(null);
    await setImmoAuthToken(null);
    await setMonPeyaAccessToken(null);
    await setMonPeyaRefreshToken(null);
    await setPeyaAccountProfile(isPeyaClient: null, isPeyapayMerchant: null);
    PeyapayHostBridge.api?.setBearerToken(null);
  }

  static Future<void> setSessionRegistered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isRegistered, value);
  }

  /// PeyaPay JWT for wallet API calls.
  static Future<String?> authToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.authToken);
  }

  static Future<void> setAuthToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(PrefsKeys.authToken);
      return;
    }
    await prefs.setString(PrefsKeys.authToken, token);
  }

  /// Mr Immo JWT
  static Future<String?> immoAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.immoAuthToken);
  }

  static Future<void> setImmoAuthToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(PrefsKeys.immoAuthToken);
      return;
    }
    await prefs.setString(PrefsKeys.immoAuthToken, token);
  }

  static Future<String?> immoUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.immoUserId);
  }

  static Future<void> setImmoUserId(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null || userId.isEmpty) {
      await prefs.remove(PrefsKeys.immoUserId);
      return;
    }
    await prefs.setString(PrefsKeys.immoUserId, userId);
  }

  static Future<String?> monPeyaAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.monPeyaAccessToken);
  }

  static Future<void> setMonPeyaAccessToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(PrefsKeys.monPeyaAccessToken);
      return;
    }
    await prefs.setString(PrefsKeys.monPeyaAccessToken, token);
  }

  static Future<String?> monPeyaRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.monPeyaRefreshToken);
  }

  static Future<void> setMonPeyaRefreshToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(PrefsKeys.monPeyaRefreshToken);
      return;
    }
    await prefs.setString(PrefsKeys.monPeyaRefreshToken, token);
  }

  static Future<String?> monPeyaUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.monPeyaUserId);
  }

  static Future<void> setMonPeyaUserId(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null || userId.isEmpty) {
      await prefs.remove(PrefsKeys.monPeyaUserId);
      return;
    }
    await prefs.setString(PrefsKeys.monPeyaUserId, userId);
  }

  static Future<String?> codeClient() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.codeClient);
  }

  static Future<void> setCodeClient(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await prefs.remove(PrefsKeys.codeClient);
      return;
    }
    await prefs.setString(PrefsKeys.codeClient, code);
  }

  /// PeyaPay account flags from Mon Peya backend (`/auth/login`, `/me`).
  static Future<void> setPeyaAccountProfile({
    bool? isPeyaClient,
    bool? isPeyapayMerchant,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (isPeyaClient == null) {
      await prefs.remove(PrefsKeys.isPeyaClient);
    } else {
      await prefs.setBool(PrefsKeys.isPeyaClient, isPeyaClient);
    }
    if (isPeyapayMerchant == null) {
      await prefs.remove(PrefsKeys.isPeyapayMerchant);
    } else {
      await prefs.setBool(PrefsKeys.isPeyapayMerchant, isPeyapayMerchant);
    }
  }

  static Future<bool?> isPeyaClientFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(PrefsKeys.isPeyaClient)) return null;
    return prefs.getBool(PrefsKeys.isPeyaClient);
  }

  static Future<bool?> isPeyapayMerchantFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(PrefsKeys.isPeyapayMerchant)) return null;
    return prefs.getBool(PrefsKeys.isPeyapayMerchant);
  }

  /// True when the signed-in phone has a PeyaPay **client** wallet
  /// (`estFournisseur: N`, `wtypeClient` CLIENT, or non-`P` `typcpt`).
  static Future<bool> hasClientWallet() async {
    final clientFlag = await isPeyaClientFlag();
    if (clientFlag == true) return true;
    if (clientFlag == false) {
      final merchant = await isPeyapayMerchantFlag();
      if (merchant == true) return false;
    }

    final state = PeyapayHostBridge.api?.clientState;
    if (state != null) {
      final resolved = PeyapayAccountProfile.resolve(sessionState: state);
      if (resolved.hasClientWallet) return true;
      if (resolved.hasMerchantWallet && !resolved.hasClientWallet) {
        return false;
      }
    }

    // Unknown — keep legacy client UX unless backend said merchant-only.
    return clientFlag ?? true;
  }

  /// Merchant / fournisseur PeyaPay without a client wallet — business UI only.
  static Future<bool> isMerchantOnly() async {
    if (await hasClientWallet()) return false;
    final merchant = await isPeyapayMerchantFlag();
    if (merchant == true) return true;
    final state = PeyapayHostBridge.api?.clientState;
    if (state != null) {
      return PeyapayAccountProfile.resolve(sessionState: state)
          .hasMerchantWallet;
    }
    return false;
  }

  /// Alias — `estFournisseur: O` without client wallet (same gate as [isMerchantOnly]).
  static Future<bool> isFournisseurOnly() => isMerchantOnly();

  /// Mon Peya subscription role after login (`FOURNISSEUR` vs `CLIENT`).
  static Future<String> serviceSubscriptionRole() async {
    if (await isFournisseurOnly()) return 'FOURNISSEUR';
    return 'CLIENT';
  }

  /// When true, modules must show business/pro side only (logged-in fournisseur).
  static Future<bool> requiresBusinessServiceUi() => isFournisseurOnly();
}
