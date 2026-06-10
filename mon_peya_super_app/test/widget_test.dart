import 'package:flutter_test/flutter_test.dart';

import 'package:mon_peya_super_app/app/app.dart';
import 'package:mon_peya_super_app/screens/onboarding/onboarding_screen.dart';
import 'package:mon_peya_super_app/screens/splash/splash_screen.dart';

void main() {
  testWidgets('Root navigator boots', (WidgetTester tester) async {
    await tester.pumpWidget(const MonPeyaSuperApp());

    // Initial route is Splash; we should at least render a widget tree.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Splash waits ~2500ms then redirects to onboarding.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
