import 'package:flutter/material.dart';

import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

class ServiceScaffold extends StatelessWidget {
  const ServiceScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: appStack.goBack,
        ),
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.apps), onPressed: appStack.toggleMenu),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

