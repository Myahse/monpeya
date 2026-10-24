import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo_superviseur/main.dart';

void main() {
  testWidgets('opens on the superviseur sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(immoSuperviseurApp);
    await tester.pumpAndSettle();

    expect(find.text('Superviseur'), findsOneWidget);
    expect(find.text('Code client'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });
}
