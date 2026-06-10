import 'package:flutter/material.dart';

import '../../../immo_brand.dart';
import '../../../shared/widgets/immo_screen_stub.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImmoScreenStub(
      appName: 'Mr Immo Construction',
      screenPath: 'messaging/screens/MessagesScreen',
      primaryColor: ImmoBrand.constructionPrimary,
    );
  }
}

