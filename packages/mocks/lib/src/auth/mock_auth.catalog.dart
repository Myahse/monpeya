import 'package:mocks/src/auth/models/mock_user.model.dart';

/// Built-in mock accounts for offline auth flows.
class MockAuthCatalog {
  MockAuthCatalog._();

  static const defaultCountryCode = '+225';
  static const defaultOtpCode = '1234';
  static const defaultPin = '1234';

  static const users = <MockUser>[
    MockUser(
      localPhone: '0777146737',
      fullPhone: '+2250777146737',
      pin: defaultPin,
      otpCode: defaultOtpCode,
      displayName: 'Demo user 1',
    ),
    MockUser(
      localPhone: '0758237837',
      fullPhone: '+2250758237837',
      pin: defaultPin,
      otpCode: defaultOtpCode,
      displayName: 'Demo user 2',
    ),
  ];

  static MockUser? findByPhone(String phone) {
    final normalized = MockAuthCatalog.normalizePhone(phone);
    for (final user in users) {
      if (normalized == user.fullPhone || normalized == user.localPhone) {
        return user;
      }
    }
    return null;
  }

  static bool isMockPhone(String phone) => findByPhone(phone) != null;

  /// Maps local 10-digit CI numbers to full international form.
  static String normalizePhone(String phone) {
    final compact = phone.trim().replaceAll(' ', '');
    if (compact.startsWith('+')) return compact;

    final digits = compact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      final match = users.cast<MockUser?>().firstWhere(
            (u) => u!.localPhone == digits,
            orElse: () => null,
          );
      if (match != null) return match.fullPhone;
      return '$defaultCountryCode$digits';
    }
    return compact;
  }
}
