import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class CreateListingStep5 extends StatelessWidget {
  const CreateListingStep5({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'creation/screens/CreateListingStep5',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}


