import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_screen_stub.widget.dart';

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({
    super.key,
    required this.onBack,
    this.onViewContract,
  });

  final VoidCallback onBack;
  final ValueChanged<String>? onViewContract;

  @override
  Widget build(BuildContext context) {
    return ImmoOverlayScreen(
      title: 'Contrats',
      primaryColor: ImmoBrand.rentalPrimary,
      onBack: onBack,
      body: ImmoScreenStub(
        appName: 'Mr Immo Location',
        screenPath: 'screens/ContractsScreen',
        primaryColor: ImmoBrand.rentalPrimary,
        footer: onViewContract == null
            ? null
            : FilledButton(
                onPressed: () => onViewContract!('demo-contract-1'),
                style: FilledButton.styleFrom(
                  backgroundColor: ImmoBrand.rentalPrimary,
                ),
                child: const Text('Ouvrir contrat (démo)'),
              ),
      ),
    );
  }
}
