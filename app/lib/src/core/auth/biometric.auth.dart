import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/storage/constants/prefs.keys.dart';

class BiometricAuth {
  BiometricAuth._();

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isEnabledInSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefsKeys.biometricEnabled) ?? false;
  }

  static Future<void> setEnabledInSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.biometricEnabled, value);
  }

  static Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) return true;
      final types = await _localAuth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({
    String reason = 'Déverrouillez Mon Peya avec la biométrie',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
