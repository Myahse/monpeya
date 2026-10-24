import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/widgets/auth_back_button.widget.dart';
import 'package:app/src/core/widgets/pin_keypad.widget.dart';
import 'package:app/src/features/auth/presentation/registration_flow/screens/registration_flow.screen.dart';
import 'package:app/src/features/auth/presentation/widgets/auth_flow_scaffold.widget.dart';

const _mismatchText = 'Les codes PIN ne correspondent pas.';

const _imagePicker = MethodChannel('plugins.flutter.io/image_picker');
const _pickedPath = '/photos/cni-recto.jpg';

/// Pumps the registration screen on a phone [size] (logical pixels, at 3x).
Future<void> _pumpOnPhone(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: RegistrationFlowScreen()));
  await tester.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Suivant'));
  await tester.pumpAndSettle();
}

/// The keypad ends right where the floating Suivant button starts: no key under it, and
/// nothing above scrolled away for no reason.
void _expectKeypadJustAboveSuivant(WidgetTester tester) {
  expect(
    tester.getRect(find.byType(PinKeypad)).bottom,
    closeTo(tester.getRect(find.widgetWithText(FilledButton, 'Suivant')).top, 1),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (phone, size) in const [
    ('a 360×800 phone', Size(360, 800)),
    ('a small 320×568 phone', Size(320, 568)),
  ]) {
    testWidgets('every step and sheet lays out inside AuthFlowScaffold on $phone', (tester) async {
      // The gallery answers with a picked file.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _imagePicker,
        (call) async => call.method == 'pickImage' ? _pickedPath : null,
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_imagePicker, null));

      await _pumpOnPhone(tester, size);

      // Step 0: the ID photos, and the sheet that picks one.
      expect(find.byType(AuthFlowScaffold), findsOneWidget);
      expect(find.text('Ajouter une photo'), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Recto'));
      await tester.pumpAndSettle();
      expect(find.text('Choisir dans la galerie'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Choisir dans la galerie'));
      await tester.pumpAndSettle();

      // The picked photo is shown from its file, as on a phone.
      expect(find.text('Ajouter une photo'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is FileImage && (w.image as FileImage).file.path == File(_pickedPath).path),
        findsOneWidget,
      );
      await _tapNext(tester);

      // Step 1: identity and email, the birth date sheet and the Sexe choice.
      expect(find.text('Vos informations'), findsOneWidget);
      expect(find.text('Profession'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Kouassi');
      await tester.enterText(fields.at(1), 'Awa');
      await tester.enterText(fields.at(2), 'awa@example.com');
      await tester.pump();

      final birthDate = find.widgetWithText(TextField, 'JJ/MM/AAAA');
      await tester.ensureVisible(birthDate);
      await tester.pumpAndSettle();
      await tester.tap(birthDate);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^\d{2}/\d{2}/\d{4}$')), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Femme').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _tapNext(tester);

      // Step 2: the PIN. The whole keypad sits above the floating Suivant button, and
      // the first PIN row stays on screen (it just fits on the small phone).
      expect(find.text('Créez votre code PIN'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
      expect(tester.takeException(), isNull);
      _expectKeypadJustAboveSuivant(tester);
      expect(tester.getRect(find.text('PIN')).top, greaterThanOrEqualTo(0));

      final keypad = find.byType(PinKeypad);
      for (final digit in ['1', '1', '1', '1', '2', '2', '2', '2']) {
        await tester.tap(find.descendant(of: keypad, matching: find.text(digit)));
        await tester.pump();
      }
      await _tapNext(tester);

      // The message pushes the keypad down; it is brought back above Suivant.
      expect(find.text(_mismatchText), findsOneWidget);
      _expectKeypadJustAboveSuivant(tester);
      expect(tester.takeException(), isNull);

      // Back to step 1 opens at the top; forward again lays the PIN step out anew.
      await tester.tap(find.byType(AuthBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Vos informations'), findsOneWidget);
      expect(tester.getRect(find.byType(Image)).top, greaterThan(0));
      await _tapNext(tester);
      expect(find.text('Créez votre code PIN'), findsOneWidget);
      _expectKeypadJustAboveSuivant(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
