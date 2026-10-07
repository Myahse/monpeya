import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grenier/src/core/host/grenier_host.bridge.dart';
import 'package:grenier/src/shared/config/grenier_api.config.dart';

/// Link between the Mon Peya user and their Mon Grenier account.
class GrenierAccountLink {
  const GrenierAccountLink({required this.accountId, required this.linkedAt});

  final String accountId;
  final DateTime linkedAt;
}

class GrenierAccountException implements Exception {
  const GrenierAccountException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Creates the Mon Grenier account from Mon Peya details (with consent) and
/// remembers the link on the device.
class GrenierAccountService {
  static const _idKey = 'grenier.account.id';
  static const _atKey = 'grenier.account.linkedAt';

  Future<GrenierAccountLink?> currentLink() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_idKey);
    final at = DateTime.tryParse(prefs.getString(_atKey) ?? '');
    if (id == null || id.isEmpty || at == null) return null;
    return GrenierAccountLink(accountId: id, linkedAt: at);
  }

  Future<GrenierAccountLink> register(GrenierHostProfile profile) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('${GrenierApiConfig.baseUrl}${GrenierApiConfig.registerPath}'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': profile.fullName,
              if (profile.phone != null) 'phone': profile.phone,
              'source': 'monpeya',
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const GrenierAccountException(
        'Impossible de joindre Mon Grenier. Vérifiez votre connexion et réessayez.',
      );
    }
    if (res.statusCode >= 400) {
      throw GrenierAccountException(
        'Mon Grenier a refusé la création du compte (${res.statusCode}).',
      );
    }
    final decoded = jsonDecode(res.body);
    final id = decoded is Map ? (decoded['id'] ?? decoded['accountId'])?.toString() : null;
    if (id == null || id.isEmpty) {
      throw const GrenierAccountException('Réponse inattendue de Mon Grenier.');
    }
    final link = GrenierAccountLink(accountId: id, linkedAt: DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, link.accountId);
    await prefs.setString(_atKey, link.linkedAt.toIso8601String());
    return link;
  }

  /// Stops sharing on this device. The partner account itself is not deleted.
  Future<void> unlink() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
    await prefs.remove(_atKey);
  }
}
