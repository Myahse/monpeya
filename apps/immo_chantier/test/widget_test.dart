import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo_chantier/main.dart';

void main() {
  testWidgets('opens on the chef de chantier sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(immoChantierApp);
    await tester.pumpAndSettle();

    expect(find.text('Chef de chantier'), findsOneWidget);
    expect(find.text('Code client'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });
}
