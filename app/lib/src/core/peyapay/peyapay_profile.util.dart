import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/storage/auth.store.dart';

/// Shared display helpers for the signed-in PeyaPay profile.
///
/// When there is no active session, UI should show [guestLabel] ("Utilisateur").
abstract final class PeyapayProfileDisplay {
  static const guestLabel = 'Utilisateur';

  static String? clientName() {
    final nom = PeyapayHostBridge.api?.clientState?.nomClient?.trim();
    if (nom == null || nom.isEmpty) return null;
    return nom;
  }

  /// Home / shell title: real name when logged in, otherwise [guestLabel].
  static Future<String> resolveHomeTitle({String fallback = guestLabel}) async {
    if (!await ModuleAuth.hasActiveSessionOrToken()) return fallback;

    final nom = clientName();
    if (nom != null) return nom;

    final phone = await AuthStore.getPhone();
    if (phone != null && phone.trim().isNotEmpty) {
      return formatPhone(phone);
    }
    return fallback;
  }

  static Future<String> resolveTitle({String guestLabel = guestLabel}) async {
    if (!await ModuleAuth.hasActiveSessionOrToken()) return guestLabel;

    final nom = clientName();
    if (nom != null) return nom;

    final phone = await AuthStore.getPhone();
    if (phone != null && phone.trim().isNotEmpty) {
      return formatPhone(phone);
    }
    return guestLabel;
  }

  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} '
          '${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    return phone.trim();
  }

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    if (name.trim() == guestLabel) return 'UT';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first;
    final last = parts.length > 1 ? parts.last : '';
    final a = first.isNotEmpty ? first[0] : '';
    final b = last.isNotEmpty ? last[0] : '';
    final res = (a + b).toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}
