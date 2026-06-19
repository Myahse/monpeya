import 'package:flutter_test/flutter_test.dart';
import 'package:mocks/mocks.dart';

void main() {
  const auth = MockAuthService();

  test('catalog includes both demo users', () {
    expect(MockAuthCatalog.users, hasLength(2));
    expect(auth.userForPhone('0758237837')?.fullPhone, '+2250758237837');
    expect(auth.userForPhone('+2250777146737')?.localPhone, '0777146737');
  });

  test('verifyOtp accepts 1234 for mock users only', () {
    expect(auth.verifyOtp('+2250758237837', '1234'), isTrue);
    expect(auth.verifyOtp('+2250758237837', '9999'), isFalse);
    expect(auth.verifyOtp('+2250102030405', '5678'), isTrue);
    expect(auth.verifyOtp('+2250102030405', '123'), isFalse);
  });

  test('normalizePhone maps local CI numbers', () {
    expect(MockAuthCatalog.normalizePhone('0777146737'), '+2250777146737');
    expect(MockAuthCatalog.normalizePhone('0758237837'), '+2250758237837');
  });
}
