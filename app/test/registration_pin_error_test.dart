import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_api.service.dart';
import 'package:app/src/features/auth/presentation/registration_flow/screens/registration_flow.screen.dart';

// The PIN step's error choice, tested through the real sign-in service without the screen
// (registration_flow_layout_test.dart pumps the screen itself).

const _mismatchText = 'Les codes PIN ne correspondent pas.';
const _pinRefusedText = 'Code PIN incorrect. Réessayez.';
const _notCheckedText = 'Service indisponible. Votre code PIN n’a pas été vérifié.';

/// What the Mon Peya backend answers /v1/auth/login with on failure (HTTP 400, hasError).
http.Response _backendError(String code, String message) => http.Response(
      jsonEncode({
        'hasError': true,
        'status': {'code': code, 'message': message},
      }),
      400,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Signs in through the real service, as the registration screen's last step does, and
/// returns what the screen would show for the failure.
Future<RegistrationPinIssue> _issueFor(MockClient client) async {
  try {
    await MonPeyaApiService(client: client).login(phone: '0700000000', pin: '1111');
  } on MonPeyaApiException catch (e) {
    return RegistrationPinIssue.fromSignInFailure(e);
  }
  fail('the sign-in was expected to fail');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a PIN PeyaPay refused (919) says the PIN is wrong, with red boxes', () async {
    final issue = await _issueFor(
      MockClient((_) async => _backendError('919', 'login et/ou mot de passe incorrect(s)')),
    );

    expect(issue, RegistrationPinIssue.refused);
    expect(issue.message, _pinRefusedText);
    expect(issue.pinIsWrong, isTrue);
  });

  test('PeyaPay unavailable (1006) never says the PIN is wrong', () async {
    final issue = await _issueFor(
      MockClient((_) async => _backendError('1006', 'Service momentanement indisponible: PeyaPay')),
    );

    expect(issue, RegistrationPinIssue.notChecked);
    expect(issue.message, _notCheckedText);
    expect(issue.pinIsWrong, isFalse);
  });

  test('an older backend refusing with 918 is not called a wrong PIN', () async {
    final issue = await _issueFor(
      MockClient((_) async => _backendError(
            '918',
            'Operation interdite/refusee: Peya admin authentication failed: '
                'login et/ou mot de passe incorrect(s)',
          )),
    );

    expect(issue, RegistrationPinIssue.notChecked);
  });

  test('the Mon Peya backend unreachable is not called a wrong PIN', () async {
    final issue = await _issueFor(
      MockClient((_) async => throw const SocketException('Connection refused')),
    );

    expect(issue, RegistrationPinIssue.notChecked);
  });

  test('only the backend LOGIN_FAIL code is a PIN refusal', () {
    expect(
      RegistrationPinIssue.fromSignInFailure(MonPeyaApiException(message: '', apiCode: '919')),
      RegistrationPinIssue.refused,
    );
    for (final code in ['1006', '920', '918', '901', null]) {
      expect(
        RegistrationPinIssue.fromSignInFailure(MonPeyaApiException(message: '', apiCode: code)),
        RegistrationPinIssue.notChecked,
        reason: '$code',
      );
    }
  });

  test('two different PINs still say they do not match, with red boxes', () {
    expect(RegistrationPinIssue.mismatch.message, _mismatchText);
    expect(RegistrationPinIssue.mismatch.pinIsWrong, isTrue);
  });
}
