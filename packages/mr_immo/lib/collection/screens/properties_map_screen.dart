import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../../shared/widgets/immo_screen_stub.dart';

class PropertiesMapScreen extends StatelessWidget {
  const PropertiesMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Collection',
      screenPath: 'screens/PropertiesMapScreen',
      primaryColor: ImmoBrand.collectionPrimary,
    );
  }
}
