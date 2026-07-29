import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_screen_stub.widget.dart';

class ContractDetailScreen extends StatelessWidget {
  const ContractDetailScreen({
    super.key,
    required this.contractId,
    required this.onBack,
  });

  final String contractId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ImmoOverlayScreen(
      title: 'Contrat',
      primaryColor: ImmoBrand.rentalPrimary,
      onBack: onBack,
      body: ImmoScreenStub(
        appName: 'Mr Immo Location',
        screenPath: 'screens/ContractDetailScreen',
        primaryColor: ImmoBrand.rentalPrimary,
        features: ['contractId: $contractId'],
      ),
    );
  }
}
