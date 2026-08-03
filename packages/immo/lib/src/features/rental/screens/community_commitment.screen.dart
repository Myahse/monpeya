import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_screen_stub.widget.dart';

class CommunityCommitmentScreen extends StatelessWidget {
  const CommunityCommitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'screens/CommunityCommitmentScreen',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}
