import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/app.dart';
import 'package:app/src/features/onboarding/presentation/screens/onboarding.screen.dart';
import 'package:app/src/features/splash/presentation/screens/splash.screen.dart';

void main() {
  testWidgets('Root navigator boots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MonPeyaSuperApp());

    // Initial route is Splash; we should at least render a widget tree.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Splash waits ~2500ms then redirects to onboarding (seenOnboarding is false).
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
