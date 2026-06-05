import 'package:flutter/material.dart';

import 'service_scaffold.dart';

class BilletterieScreen extends StatelessWidget {
  const BilletterieScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ServiceScaffold(
      title: 'Billetterie',
      child: Text('Billetterie moduleId=$moduleId (placeholder)'),
    );
  }
}

