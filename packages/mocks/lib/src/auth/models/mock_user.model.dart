/// Pre-seeded account used in dev / demo builds (no real SMS or backend).
class MockUser {
  const MockUser({
    required this.localPhone,
    required this.fullPhone,
    required this.pin,
    required this.otpCode,
    this.displayName,
  });

  /// 10-digit local number, e.g. `0777146737`.
  final String localPhone;

  /// E.164-style number with country code, e.g. `+2250777146737`.
  final String fullPhone;

  /// App login PIN.
  final String pin;

  /// SMS validation code shown in the OTP sheet.
  final String otpCode;

  final String? displayName;
}
