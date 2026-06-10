import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../../shared/widgets/immo_screen_stub.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'screens/SearchScreen',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}
