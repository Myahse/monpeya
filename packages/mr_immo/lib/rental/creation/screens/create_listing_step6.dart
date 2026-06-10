import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class CreateListingStep6 extends StatelessWidget {
  const CreateListingStep6({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'creation/screens/CreateListingStep6',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}


