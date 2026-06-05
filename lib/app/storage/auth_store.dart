import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'prefs_keys.dart';

class AuthStore {
  static String _pinKey(String phone) => 'pin:$phone';
  // Demo credentials (used when user chooses to login).
  static const String demoPhoneLocal = '0777146737';
  static const String demoPhoneFull = '+2250777146737';
  static const String demoPin = '1234';


  static const bool forceGuestInDebug = false;

  static bool get _forceGuest => kDebugMode && forceGuestInDebug;

  static String _normalizePhone(String phone) {
    final p = phone.trim().replaceAll(' ', '');
    if (p.startsWith('+')) return p;
    
    if (p == demoPhoneLocal) return demoPhoneFull;
    return p;
  }

  static bool _isDemoPhone(String phone) => _normalizePhone(phone) == demoPhoneFull;

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
    if (_isDemoPhone(normalized)) {
      return true;
    }
    return prefs.containsKey(_pinKey(normalized));
  }

  static Future<String?> getPinForPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizePhone(phone);
    if (_isDemoPhone(normalized)) {
      // Always accept demo PIN, even if prefs were cleared.
      // We still seed prefs to keep the rest of the app consistent.
      await prefs.setString(_pinKey(demoPhoneFull), demoPin);
      return demoPin;
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

  static Future<void> loginDemoUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.phoneNumber, demoPhoneFull);
    await prefs.setString(_pinKey(demoPhoneFull), demoPin);
    await prefs.setBool(PrefsKeys.isRegistered, true);
  }

  static Future<void> setSessionRegistered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isRegistered, value);
  }
}

