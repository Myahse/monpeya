import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:mocks/mocks.dart';

import 'package:app/src/core/storage/constants/prefs.keys.dart';

class AuthStore {
  AuthStore._();

  static const _mockAuth = MockAuthService();

  static String _pinKey(String phone) => 'pin:$phone';

  /// First catalog user — kept for backwards compatibility in docs / tooling.
  static MockUser get primaryMockUser => MockAuthCatalog.users.first;

  static const bool forceGuestInDebug = false;

  static bool get _forceGuest => kDebugMode && forceGuestInDebug;

  static String _normalizePhone(String phone) => _mockAuth.normalizePhone(phone);

  static bool _isMockPhone(String phone) => _mockAuth.isMockUser(phone);

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.phoneNumber);
  }

  static Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.phoneNumber, phone);
  }

  static Future<bool> hasPinForPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizePhone(phone);
    if (_isMockPhone(normalized)) {
      return true;
    }
    return prefs.containsKey(_pinKey(normalized));
  }

  static Future<String?> getPinForPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizePhone(phone);
    final mockPin = _mockAuth.pinForPhone(normalized);
    if (mockPin != null) {
      await prefs.setString(_pinKey(normalized), mockPin);
      return mockPin;
    }
    return prefs.getString(_pinKey(normalized));
  }

  static Future<void> setPinForPhone(String phone, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey(_normalizePhone(phone)), pin);
  }

  static Future<bool> isRegistered() async {
    if (_forceGuest) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefsKeys.isRegistered) ?? false;
  }

  /// Account exists on device (phone + PIN stored after registration).
  static Future<bool> hasAccount() async {
    if (_forceGuest) return false;
    if (!await isRegistered()) return false;
    final phone = await getPhone();
    if (phone == null || phone.trim().isEmpty) return false;
    return hasPinForPhone(phone);
  }

  /// Ends the current session but keeps phone/PIN for next PIN login.
  static Future<void> endSession() async {
    await setAuthToken(null);
  }

  static Future<void> loginMockUser([MockUser? user]) async {
    final mock = user ?? primaryMockUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.phoneNumber, mock.fullPhone);
    await prefs.setString(_pinKey(mock.fullPhone), mock.pin);
    await prefs.setBool(PrefsKeys.isRegistered, true);
  }

  static Future<void> setSessionRegistered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isRegistered, value);
  }

  /// JWT for Spring Boot API calls and WebView auth handoff.
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
}
