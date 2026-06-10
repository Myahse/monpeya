import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class CreateTenantStep2 extends StatelessWidget {
  const CreateTenantStep2({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'creation/screens/CreateTenantStep2',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}


