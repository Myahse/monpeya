import 'package:flutter/material.dart';

import '../../app/widgets/simple_scaffold.dart';

class ResetPinScreen extends StatelessWidget {
  const ResetPinScreen({super.key});
  static const routeName = '/reset-pin';

  @override
  Widget build(BuildContext context) {
    return const SimpleScaffold(
      title: 'Reset PIN',
      body: Text('Reset PIN placeholder.'),
    );
  }
}

