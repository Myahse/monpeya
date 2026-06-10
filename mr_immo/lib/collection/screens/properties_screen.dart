import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../../shared/widgets/immo_screen_stub.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({
    super.key,
    required this.onBack,
    this.onSelectProperty,
    this.onViewPayments,
  });

  final VoidCallback onBack;
  final ValueChanged<String>? onSelectProperty;
  final void Function(String propertyId, String contractId)? onViewPayments;

  @override
  Widget build(BuildContext context) {
    return ImmoOverlayScreen(
      title: 'Biens',
      primaryColor: ImmoBrand.collectionPrimary,
      onBack: onBack,
      body: ImmoScreenStub(
        appName: 'Mr Immo Collection',
        screenPath: 'screens/PropertiesScreen',
        primaryColor: ImmoBrand.collectionPrimary,
        features: const [
          'Liste immeubles / lots',
          'Fiche locataire',
        ],
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onSelectProperty != null)
              FilledButton(
                onPressed: () => onSelectProperty!('demo-property-1'),
                style: FilledButton.styleFrom(
                  backgroundColor: ImmoBrand.collectionPrimary,
                ),
                child: const Text('Sélectionner bien (démo)'),
              ),
            if (onViewPayments != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => onViewPayments!('demo-property-1', 'demo-contract-1'),
                child: const Text('Voir paiements (démo)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
