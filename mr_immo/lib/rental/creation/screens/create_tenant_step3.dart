import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class CreateTenantStep3 extends StatelessWidget {
  const CreateTenantStep3({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'creation/screens/CreateTenantStep3',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}


