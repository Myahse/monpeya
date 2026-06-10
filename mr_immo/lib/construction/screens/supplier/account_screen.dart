import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Construction',
      screenPath: 'screens/supplier/AccountScreen',
      primaryColor: ImmoBrand.constructionPrimary,
    );
  }
}

