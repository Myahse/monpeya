import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../../shared/widgets/immo_screen_stub.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Construction',
      screenPath: 'screens/LoginScreen',
      primaryColor: ImmoBrand.constructionPrimary,
    );
  }
}


