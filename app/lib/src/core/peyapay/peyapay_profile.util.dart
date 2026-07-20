import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/storage/auth.store.dart';

/// Display helpers for PeyaPay client profile (name from `/wClients/etatclient`).
abstract final class PeyapayProfileDisplay {
  static String? clientName() {
    final nom = PeyapayHostBridge.api?.clientState?.nomClient?.trim();
    if (nom == null || nom.isEmpty) return null;
    return nom;
  }

  static String resolveHomeTitle({String fallback = 'Mon Peya'}) {
    return clientName() ?? fallback;
  }

  static Future<String> resolveTitle({String guestLabel = 'Mon Peya'}) async {
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
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first;
    final last = parts.length > 1 ? parts.last : '';
    final a = first.isNotEmpty ? first[0] : '';
    final b = last.isNotEmpty ? last[0] : '';
    final res = (a + b).toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}
