import 'package:flutter/material.dart';

import '../../screens/app_stack/app_stack_screen.dart';
import '../../screens/auth/login_pin/login_pin_screen.dart';
import '../../screens/auth/phone_input/phone_input_screen.dart';
import '../../screens/auth/registration_flow/registration_flow_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/reset_pin/reset_pin_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';

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

