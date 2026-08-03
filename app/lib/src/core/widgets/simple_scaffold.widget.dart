import 'package:flutter/material.dart';

import 'package:app/src/core/navigation/app.navigation.dart';

class SimpleScaffold extends StatelessWidget {
  const SimpleScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => AppNavigation.pop(context),
        ),
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}
