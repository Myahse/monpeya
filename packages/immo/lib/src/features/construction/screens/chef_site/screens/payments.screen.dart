import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_screen_stub.widget.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Construction',
      screenPath: 'screens/chef-site/PaymentsScreen',
      primaryColor: ImmoBrand.constructionPrimary,
    );
  }
}

