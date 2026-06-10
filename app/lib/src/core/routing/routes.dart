import 'package:flutter/material.dart';

import 'package:app/src/features/shell/screens/app_stack.screen.dart';
import 'package:app/src/features/auth/presentation/login_pin/screens/login_pin.screen.dart';
import 'package:app/src/features/auth/presentation/phone_input/screens/phone_input.screen.dart';
import 'package:app/src/features/auth/presentation/registration_flow/screens/registration_flow.screen.dart';
import 'package:app/src/features/onboarding/presentation/screens/onboarding.screen.dart';
import 'package:app/src/features/reset_pin/presentation/screens/reset_pin.screen.dart';
import 'package:app/src/features/settings/presentation/screens/settings.screen.dart';
import 'package:app/src/features/splash/presentation/screens/splash.screen.dart';

final rootNavKey = GlobalKey<NavigatorState>();

class Routes {
  static const splash = SplashScreen.routeName;
  static const onboarding = OnboardingScreen.routeName;
  static const phoneInput = PhoneInputScreen.routeName;
  static const registrationFlow = RegistrationFlowScreen.routeName;
  static const loginPin = LoginPinScreen.routeName;
  static const settings = SettingsScreen.routeName;
  static const resetPin = ResetPinScreen.routeName;
  static const app = AppStackScreen.routeName;
}

Map<String, WidgetBuilder> buildRoutes() {
  return {
    SplashScreen.routeName: (_) => const SplashScreen(),
    OnboardingScreen.routeName: (_) => const OnboardingScreen(),
    PhoneInputScreen.routeName: (_) => const PhoneInputScreen(),
    RegistrationFlowScreen.routeName: (_) => const RegistrationFlowScreen(),
    LoginPinScreen.routeName: (_) => const LoginPinScreen(),
    SettingsScreen.routeName: (_) => const SettingsScreen(),
    ResetPinScreen.routeName: (_) => const ResetPinScreen(),
    AppStackScreen.routeName: (_) => const AppStackScreen(),
  };
}

