import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class CreateTenantStep4 extends StatelessWidget {
  const CreateTenantStep4({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'creation/screens/CreateTenantStep4',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}


