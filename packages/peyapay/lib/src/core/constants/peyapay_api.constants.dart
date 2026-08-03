import 'package:peyapay/src/core/config/peyapay_env.registry.dart';


class PeyapayApiConfig {
  PeyapayApiConfig._();

  static const defaultDevBaseUrl = 'https://test1-pey-peya.djogana-pay.com';
  static const defaultProdBaseUrl = 'https://peya.djogana-pay.com:7443';
  static const defaultCryptoBaseUrl = 'https://djoganapayci.com/api10/peya-2.0/ncg';
  static const defaultTokenEndpoint = '/authclient/token';

  static String get baseUrl {
    final runtime = PeyapayEnvRegistry.apiUrl;
    if (runtime != null && runtime.isNotEmpty) return runtime;

    final useProd = PeyapayEnvRegistry.useProd ?? false;
    return useProd ? defaultProdBaseUrl : defaultDevBaseUrl;
  }

  static String get cryptoBaseUrl {
    final runtime = PeyapayEnvRegistry.cryptoUrl;
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return defaultCryptoBaseUrl;
  }

  static String get tokenEndpoint {
    final runtime = PeyapayEnvRegistry.tokenEndpoint;
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return defaultTokenEndpoint;
  }

  static String get appUsername => PeyapayEnvRegistry.appUsername ?? '';

  static String get appPassword => PeyapayEnvRegistry.appPassword ?? '';

  static String get appToken => PeyapayEnvRegistry.appToken ?? '';

  static String get encryptKey => PeyapayEnvRegistry.encryptKey ?? '';

  static String get qrEncryptKey {
    final qr = PeyapayEnvRegistry.qrEncryptKey;
    if (qr != null && qr.isNotEmpty) return qr;
    return encryptKey;
  }

  static const apiTimeout = Duration(seconds: 30);
  static const defaultResidenceCountry = 'CI';
  static const defaultAgenceCode = '11111';
}
