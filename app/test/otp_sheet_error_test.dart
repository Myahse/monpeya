import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_api.service.dart';
import 'package:app/src/core/widgets/pin_keypad.widget.dart';
import 'package:app/src/features/auth/presentation/phone_input/screens/phone_input.screen.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

const _refusedText = 'Code OTP invalide';
const _notCheckedText = 'Service indisponible. Votre code OTP n’a pas été vérifié.';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Map<String, dynamic> item) => http.Response(
      jsonEncode({
        'hasError': false,
        'status': {'code': '800', 'message': ''},
        'item': item,
      }),
      200,
      headers: _json,
    );

/// What the Mon Peya backend answers on failure (HTTP 400, hasError).
http.Response _backendError(String code, String message) => http.Response(
      jsonEncode({
        'hasError': true,
        'status': {'code': code, 'message': message},
      }),
      400,
      headers: _json,
    );

/// An unknown number: the lookup says so and the OTP goes out; [verify] answers the code.
MockClient _backend(Future<http.Response> Function() verify) => MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/v1/auth/lookup')) return _ok({'knownPeyaClient': false, 'otpRequired': true});
      if (path.endsWith('/v1/auth/otp/send')) return _ok({'otpRequired': true});
      if (path.endsWith('/v1/auth/otp/verify')) return verify();
      return _backendError('404', 'unexpected $path');
    });

/// Enters a number, opens the OTP sheet, types a code and taps its Suivant.
Future<void> _submitOtp(WidgetTester tester, http.Client client) async {
  registerMonPeyaApi(api: MonPeyaApiService(client: client));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: PhoneInputScreen()));
  await tester.enterText(find.byType(TextField), '0700000000');
  await tester.pump();
  await tester.tap(find.text('Suivant'));
  // Keyboard delays, lookup, OTP send, then the sheet; the screen's busy spinner never settles.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  final keypad = find.byType(PinKeypad);
  expect(keypad, findsOneWidget);
  for (var i = 0; i < 4; i++) {
    await tester.tap(find.descendant(of: keypad, matching: find.text('1')));
    await tester.pump();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'Suivant'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Unmounts, then lets the resend countdown's pending tick run and stop.
Future<void> _closeSheet(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

Color _codeBoxBorderColor(WidgetTester tester) {
  final box = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) => c.padding == const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      );
  final border = (box.decoration! as BoxDecoration).border! as Border;
  return border.top.color;
}

ColorScheme _colors(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(PinKeypad))).colorScheme;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => registerMonPeyaApi());

  testWidgets('a code PeyaPay refused (920) says the OTP is invalid', (tester) async {
    await _submitOtp(
      tester,
      _backend(() async => _backendError('920', 'Operation interdite/refusee: code invalide')),
    );

    expect(find.text(_refusedText), findsOneWidget);
    expect(find.text(_notCheckedText), findsNothing);
    expect(_codeBoxBorderColor(tester), _colors(tester).error);
    await _closeSheet(tester);
  });

  testWidgets('PeyaPay unavailable (1006) never says the OTP is invalid', (tester) async {
    await _submitOtp(
      tester,
      _backend(() async => _backendError('1006', 'Service momentanement indisponible: PeyaPay')),
    );

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_refusedText), findsNothing);
    expect(_codeBoxBorderColor(tester), _colors(tester).outlineVariant);
    await _closeSheet(tester);
  });

  testWidgets('an older backend refusing with 918 is not called an invalid OTP', (tester) async {
    await _submitOtp(
      tester,
      _backend(() async => _backendError(
            '918',
            'Operation interdite/refusee: Peya admin authentication failed: '
                'login et/ou mot de passe incorrect(s)',
          )),
    );

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_refusedText), findsNothing);
    await _closeSheet(tester);
  });

  testWidgets('the Mon Peya backend unreachable is not called an invalid OTP', (tester) async {
    await _submitOtp(
      tester,
      _backend(() async => throw const SocketException('Connection refused')),
    );

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_refusedText), findsNothing);
    await _closeSheet(tester);
  });

  test('only the backend DISALLOWED_OPERATION code is an OTP refusal', () {
    expect(MonPeyaApiException(message: '', apiCode: '920').isOtpRefused, isTrue);
    for (final code in ['1006', '919', '918', '901', null]) {
      expect(MonPeyaApiException(message: '', apiCode: code).isOtpRefused, isFalse, reason: '$code');
    }
  });
}
