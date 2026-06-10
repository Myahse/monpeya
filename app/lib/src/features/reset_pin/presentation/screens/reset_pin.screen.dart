import 'package:flutter/material.dart';

import 'package:app/src/core/widgets/simple_scaffold.widget.dart';

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

