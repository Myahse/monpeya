import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/api/mon_peya_api.service.dart';
import 'package:app/src/core/api/mon_peya_error.messages.dart';
import 'package:app/src/core/storage/constants/prefs.keys.dart';
import 'package:app/src/features/auth/presentation/registration_flow/screens/registration_flow.screen.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

const _mismatchText = 'Les codes PIN ne correspondent pas.';
const _pinRefusedText = 'Code PIN incorrect. Réessayez.';
const _notCheckedText = 'Service indisponible. Votre code PIN n’a pas été vérifié.';

const _imagePicker = MethodChannel('plugins.flutter.io/image_picker');

/// What the Mon Peya backend answers /v1/auth/login with on failure (HTTP 400, hasError).
http.Response _backendError(String code, String message) => http.Response(
      jsonEncode({
        'hasError': true,
        'status': {'code': code, 'message': message},
      }),
      400,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Walks the flow to the PIN step: a recto photo, then the three required fields.
Future<void> _reachPinStep(WidgetTester tester, http.Client client) async {
  registerMonPeyaApi(api: MonPeyaApiService(client: client));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: RegistrationFlowScreen()));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Recto'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choisir dans la galerie'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).at(0), 'Test');
  await tester.enterText(find.byType(TextField).at(1), 'Test');
  await tester.enterText(find.byType(TextField).at(2), 'test@example.com');
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
}

/// Types [pin] then [confirm] on the keypad and taps Suivant.
Future<void> _submitPins(WidgetTester tester, {String pin = '1111', String confirm = '1111'}) async {
  for (final digit in (pin + confirm).split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
}

Color _pinBoxBorderColor(WidgetTester tester) {
  final box = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) => c.constraints?.maxWidth == 256,
      );
  final border = (box.decoration! as BoxDecoration).border! as Border;
  return border.top.color;
}

ColorScheme _colors(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(RegistrationFlowScreen))).colorScheme;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({PrefsKeys.phoneNumber: '+2250700000000'});
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_imagePicker, (_) async => '/tmp/recto.jpg');
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_imagePicker, null);
    registerMonPeyaApi();
  });

  testWidgets('a PIN PeyaPay refused (919) says the PIN is wrong', (tester) async {
    await _reachPinStep(
      tester,
      MockClient((_) async => _backendError('919', 'login et/ou mot de passe incorrect(s)')),
    );
    await _submitPins(tester);

    expect(find.text(_pinRefusedText), findsOneWidget);
    expect(find.text(_mismatchText), findsNothing);
    expect(find.text(_notCheckedText), findsNothing);
    expect(_pinBoxBorderColor(tester), _colors(tester).error);
  });

  testWidgets('PeyaPay unavailable (1006) never says the PIN is wrong', (tester) async {
    await _reachPinStep(
      tester,
      MockClient((_) async => _backendError('1006', 'Service momentanement indisponible: PeyaPay')),
    );
    await _submitPins(tester);

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_pinRefusedText), findsNothing);
    expect(find.text(_mismatchText), findsNothing);
    expect(find.text(MonPeyaErrorMessages.peyaPayUnavailable), findsOneWidget);
    expect(_pinBoxBorderColor(tester), _colors(tester).outlineVariant);
  });

  testWidgets('an older backend refusing with 918 is not called a wrong PIN', (tester) async {
    await _reachPinStep(
      tester,
      MockClient((_) async => _backendError(
            '918',
            'Operation interdite/refusee: Peya admin authentication failed: '
                'login et/ou mot de passe incorrect(s)',
          )),
    );
    await _submitPins(tester);

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_pinRefusedText), findsNothing);
    expect(find.text(_mismatchText), findsNothing);
  });

  testWidgets('the Mon Peya backend unreachable is not called a wrong PIN', (tester) async {
    await _reachPinStep(
      tester,
      MockClient((_) async => throw const SocketException('Connection refused')),
    );
    await _submitPins(tester);

    expect(find.text(_notCheckedText), findsOneWidget);
    expect(find.text(_pinRefusedText), findsNothing);
    expect(find.text(_mismatchText), findsNothing);
  });

  testWidgets('two different PINs still say they do not match, without signing in', (tester) async {
    var calls = 0;
    await _reachPinStep(
      tester,
      MockClient((_) async {
        calls++;
        return _backendError('1006', 'Service momentanement indisponible: PeyaPay');
      }),
    );
    await _submitPins(tester, pin: '1111', confirm: '2222');

    expect(find.text(_mismatchText), findsOneWidget);
    expect(find.text(_notCheckedText), findsNothing);
    expect(_pinBoxBorderColor(tester), _colors(tester).error);
    expect(calls, 0);
  });

  testWidgets('typing again after an error clears it', (tester) async {
    await _reachPinStep(
      tester,
      MockClient((_) async => _backendError('1006', 'Service momentanement indisponible: PeyaPay')),
    );
    await _submitPins(tester);
    expect(find.text(_notCheckedText), findsOneWidget);

    // The SnackBar covers the keypad until it goes.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump();

    expect(find.text(_notCheckedText), findsNothing);
  });
}
