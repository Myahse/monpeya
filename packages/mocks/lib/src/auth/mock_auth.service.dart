import 'package:mocks/src/auth/mock_auth.catalog.dart';
import 'package:mocks/src/auth/models/mock_user.model.dart';

/// Simulates OTP and PIN checks against [MockAuthCatalog].
class MockAuthService {
  const MockAuthService();

  MockUser? userForPhone(String phone) => MockAuthCatalog.findByPhone(phone);

  bool isMockUser(String phone) => MockAuthCatalog.isMockPhone(phone);

  String normalizePhone(String phone) => MockAuthCatalog.normalizePhone(phone);

  /// Returns `true` when [code] matches the mock SMS code for [phone].
  bool verifyOtp(String phone, String code) {
    final user = userForPhone(phone);
    if (user == null) {
      // Non-mock numbers: any 4-digit code accepted in dev.
      return code.length == 4;
    }
    return code == user.otpCode;
  }

  /// Returns the mock PIN when [phone] is a catalog user.
  String? pinForPhone(String phone) => userForPhone(phone)?.pin;

  bool hasPinForPhone(String phone) => pinForPhone(phone) != null;
}
