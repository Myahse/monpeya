class MonPeyaApiException implements Exception {
  MonPeyaApiException({
    required this.message,
    this.statusCode,
    this.apiCode,
  });

  /// Backend LOGIN_FAIL: PeyaPay checked the PIN and refused it.
  static const pinRefusedCode = '919';

  /// Backend TECH_SERVICE_UNAVAILABLE: PeyaPay could not be used, nothing was checked.
  static const serviceUnavailableCode = '1006';

  /// Backend DISALLOWED_OPERATION: PeyaPay answered and refused (on OTP verify, the code).
  static const peyaPayRefusedCode = '920';

  final String message;
  final int? statusCode;
  final String? apiCode;

  /// Only this means a wrong PIN; any other failure left the PIN unchecked.
  bool get isPinRefused => apiCode == pinRefusedCode;

  /// On OTP verify, only this means a wrong code; any other failure left it unchecked.
  bool get isOtpRefused => apiCode == peyaPayRefusedCode;

  @override
  String toString() => 'MonPeyaApiException($message${apiCode != null ? ', code=$apiCode' : ''})';
}
