import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_screen_stub.widget.dart';

class CreateTenantStep1 extends StatelessWidget {
  const CreateTenantStep1({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'creation/screens/CreateTenantStep1',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}


