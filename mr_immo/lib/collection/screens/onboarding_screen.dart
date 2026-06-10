import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../../shared/widgets/immo_screen_stub.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Collection',
      screenPath: 'screens/OnboardingScreen',
      primaryColor: ImmoBrand.collectionPrimary,
    );
  }
}
