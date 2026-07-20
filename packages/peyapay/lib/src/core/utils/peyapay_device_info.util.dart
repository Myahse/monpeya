import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Device fingerprint used by PeyaPay wallet endpoints.
class PeyapayDeviceInfo {
  PeyapayDeviceInfo._();

  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    var model = 'Unknown Device';
    var platform = 'unknown';
    var imei = 'unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        model = androidInfo.model;
        platform = 'android';

        final androidId = androidInfo.id;
        if (androidId.isNotEmpty) {
          imei = _pseudoImeiFromId(androidId);
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        model = iosInfo.model;
        platform = 'ios';

        final identifier = iosInfo.identifierForVendor;
        if (identifier != null && identifier.isNotEmpty) {
          imei = _pseudoImeiFromId(identifier);
        }
      }
    } catch (_) {}

    return {
   
      'imei': imei,
      'modele': model,
      'plateform': platform,
    };
  }

  static String _pseudoImeiFromId(String id) {
    final cleaned = id.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.isEmpty) return 'unknown';

    final digits = cleaned.split('').map((char) {
      final hexValue = int.parse(char, radix: 16);
      return (hexValue % 10).toString();
    }).join();

    final length = cleaned.length > 15 ? 15 : cleaned.length;
    return digits.substring(0, length).padRight(15, '0');
  }
}
