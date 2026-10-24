import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo_fournisseur/main.dart';

void main() {
  testWidgets('opens on the fournisseur sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(immoFournisseurApp);
    await tester.pumpAndSettle();

    expect(find.text('Fournisseur'), findsOneWidget);
    expect(find.text('Code client'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });
}
