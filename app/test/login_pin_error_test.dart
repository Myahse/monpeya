import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_api.service.dart';
import 'package:app/src/core/api/mon_peya_error.messages.dart';
import 'package:app/src/features/auth/presentation/login_pin/screens/login_pin.screen.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

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

Future<void> _enterPin(WidgetTester tester, http.Client client) async {
  registerMonPeyaApi(api: MonPeyaApiService(client: client));
  // A phone screen: the PIN screen's column needs more height than the 800×600 default.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: LoginPinScreen(phoneNumber: '0700000000')),
  );
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.tap(find.text('1'));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Color _pinBoxBorderColor(WidgetTester tester) {
  final box = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) => c.constraints?.maxWidth == 240,
      );
  final border = (box.decoration! as BoxDecoration).border! as Border;
  return border.top.color;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => registerMonPeyaApi());

  testWidgets('a PIN PeyaPay refused (919) says the PIN is wrong', (tester) async {
    await _enterPin(
      tester,
      MockClient((_) async => _backendError('919', 'login et/ou mot de passe incorrect(s)')),
    );

    expect(find.text(_pinRefusedText), findsOneWidget);
    expect(find.text(_notCheckedText), findsNothing);
    expect(_pinBoxBorderColor(tester), const Color(0xFFEF4444));
  });

  testWidgets('PeyaPay unavailable (1006) never says the PIN is wrong', (tester) async {
    await _enterPin(
      tester,
      MockClient((_) async => _backendError('1006', 'Service momentanement indisponible: PeyaPay')),
    );

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_pinRefusedText), findsNothing);
    expect(find.text(MonPeyaErrorMessages.peyaPayUnavailable), findsOneWidget);
    expect(_pinBoxBorderColor(tester), const Color(0xFF9CA3AF));
  });

  testWidgets('an older backend refusing with 918 or 920 is not called a wrong PIN', (tester) async {
    await _enterPin(
      tester,
      MockClient((_) async => _backendError(
            '918',
            'Operation interdite/refusee: Peya admin authentication failed: '
                'login et/ou mot de passe incorrect(s)',
          )),
    );

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_pinRefusedText), findsNothing);
  });

  testWidgets('the Mon Peya backend unreachable is not called a wrong PIN', (tester) async {
    await _enterPin(
      tester,
      MockClient((_) async => throw const SocketException('Connection refused')),
    );

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_pinRefusedText), findsNothing);
  });

  testWidgets('typing again after an error clears it', (tester) async {
    await _enterPin(
      tester,
      MockClient((_) async => _backendError('1006', 'Service momentanement indisponible: PeyaPay')),
    );
    expect(find.text(_notCheckedText), findsOneWidget);

    // The SnackBar covers the keypad until it goes.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump();

    expect(find.text(_notCheckedText), findsNothing);
  });

  test('only the backend LOGIN_FAIL code is a PIN refusal', () {
    expect(MonPeyaApiException(message: '', apiCode: '919').isPinRefused, isTrue);
    for (final code in ['1006', '920', '918', '901', null]) {
      expect(MonPeyaApiException(message: '', apiCode: code).isPinRefused, isFalse, reason: '$code');
    }
  });
}
