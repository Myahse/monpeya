import 'package:flutter/material.dart';

import '../app_stack_scope.dart';
import '../app_stack_types.dart';
import '../widgets/module_scaffold.dart';
import '../widgets/placeholder_screen.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.maybeOf(context);
    return ModuleScaffold(
      title: 'MY SUBS',
      children: [
        const ModuleHeader(title: 'My subscriptions', subtitle: 'Services you subscribed to'),
        ModuleTile(
          icon: Icons.grid_view_outlined,
          title: 'My services',
          subtitle: 'Open service modules',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlaceholderScreen(title: 'My services')),
          ),
        ),
        ModuleTile(
          icon: Icons.widgets_outlined,
          title: 'Service module (generic)',
          subtitle: 'Loads a module by moduleId + bundleUrl',
          onTap: () => appStack?.openService(
            AppStackRoute.serviceModule,
            params: const {'moduleId': 'demo-module', 'bundleUrl': 'https://example.com/bundle.js'},
          ),
        ),
      ],
    );
  }
}

