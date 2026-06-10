import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_screen_stub.widget.dart';

class RentCollectionScreen extends StatelessWidget {
  const RentCollectionScreen({
    super.key,
    required this.onBack,
    this.propertyId,
    this.contractId,
  });

  final VoidCallback onBack;
  final String? propertyId;
  final String? contractId;

  @override
  Widget build(BuildContext context) {
    final features = <String>[
      if (propertyId != null) 'propertyId: $propertyId',
      if (contractId != null) 'contractId: $contractId',
      'Échéances du mois',
      'Relances & encaissements',
    ];

    return ImmoOverlayScreen(
      title: 'Recouvrement',
      primaryColor: ImmoBrand.collectionDark,
      onBack: onBack,
      body: ImmoScreenStub(
        appName: 'Mr Immo Collection',
        screenPath: 'screens/RentCollectionScreen',
        primaryColor: ImmoBrand.collectionDark,
        features: features,
      ),
    );
  }
}
