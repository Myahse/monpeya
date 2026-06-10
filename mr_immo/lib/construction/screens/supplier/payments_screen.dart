import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Construction',
      screenPath: 'screens/supplier/PaymentsScreen',
      primaryColor: ImmoBrand.constructionPrimary,
    );
  }
}

