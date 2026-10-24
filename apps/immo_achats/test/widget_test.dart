import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo_achats/main.dart';

void main() {
  testWidgets('opens on the moyens généraux sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(immoAchatsApp);
    await tester.pumpAndSettle();

    expect(find.text('Moyens généraux'), findsOneWidget);
    expect(find.text('Code client'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });
}
