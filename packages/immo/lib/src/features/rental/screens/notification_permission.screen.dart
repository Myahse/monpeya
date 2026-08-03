import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/widgets/immo_screen_stub.widget.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Location',
      screenPath: 'screens/NotificationPermissionScreen',
      primaryColor: ImmoBrand.rentalPrimary,
      
    );
  }
}
