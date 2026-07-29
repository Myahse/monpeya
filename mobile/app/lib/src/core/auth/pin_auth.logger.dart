import 'package:flutter/foundation.dart';

/// Debug-only tracing for PIN login / storage — never logs the PIN itself.
abstract final class PinAuthLogger {
  static const _tag = '[PinAuth]';

  static void step(String message) {
    if (kDebugMode) debugPrint('$_tag $message');
  }

  static void success(String message) => step('OK $message');

  static void failure(String message, [Object? error]) {
    if (!kDebugMode) return;
    if (error == null) {
      debugPrint('$_tag FAIL $message');
      return;
    }
    debugPrint('$_tag FAIL $message — $error');
  }

  static String maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '(no phone)';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '****';
    return '***${digits.substring(digits.length - 4)}';
  }

  static String maskPinLength(int length) => '**** ($length digits)';

  static String maskCipher(String cipher) {
    if (cipher.isEmpty) return '(empty)';
    final head = cipher.length <= 12 ? cipher : '${cipher.substring(0, 12)}…';
    return '$head (${cipher.length} chars)';
  }
}
