import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../../shared/widgets/immo_screen_stub.dart';

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
