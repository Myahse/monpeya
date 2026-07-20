import 'package:peyapay/src/data/services/peyapay_crypto.service.dart';


class PeyapayWalletQrCache {
  PeyapayWalletQrCache._();

  static final PeyapayWalletQrCache instance = PeyapayWalletQrCache._();

  String? _phoneDigits;
  String? _qrContent;

  String? contentForPhone(String? phone) {
    if (_qrContent == null || _phoneDigits == null) return null;
    if (phone == null || phone.isEmpty) return _qrContent;
    final digits = normalizePeyapayPhone(phone);
    if (digits != _phoneDigits) return null;
    return _qrContent;
  }

  String? get lastContent => _qrContent;

  void save({required String phone, required String qrContent}) {
    _phoneDigits = normalizePeyapayPhone(phone);
    _qrContent = qrContent;
  }

  void clear() {
    _phoneDigits = null;
    _qrContent = null;
  }
}

void clearPeyapayWalletQrCache() => PeyapayWalletQrCache.instance.clear();
