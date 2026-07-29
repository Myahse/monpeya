/// Compact payload keys for PeyaPay wallet QR codes (secure_qr_generator 1.1+).
abstract final class PeyapayQrKeys {
  static const clientCode = 'cck';
  static const phone = 'pk';
  static const userNames = 'uk';
  static const userType = 'uyk';
  static const traitementId = 'tik';
}

abstract final class PeyapayQrConstants {
  PeyapayQrConstants._();

  /// Wallet QR lifetime in seconds (matches Djogana `QRCODE_GENERATOR_VALIDITY_TIME`).
  static const generatorValiditySeconds = 300;
}
