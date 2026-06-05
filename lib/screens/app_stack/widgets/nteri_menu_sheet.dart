import 'package:flutter/material.dart';

import '../../../app/routing/routes.dart';
import '../../settings/settings_screen.dart';
import '../app_stack_scope.dart';
import '../app_stack_types.dart';

class NteriMenuSheet extends StatelessWidget {
  const NteriMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appStack = AppStackScope.of(context);

    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Icons.home_outlined, label: 'Tableau de bord', onTap: appStack.navigateToMain),
      (
        icon: Icons.confirmation_number_outlined,
        label: 'Billetterie',
        onTap: () => appStack.openService(
          AppStackRoute.billetterie,
          params: const {'moduleId': 'billetterie-electronique'},
        ),
      ),
      (
        icon: Icons.apartment_outlined,
        label: 'Mr Immo (Rental)',
        onTap: () => appStack.openService(
          AppStackRoute.mrImmoRental,
          params: const {'moduleId': 'mr-immo-rental'},
        ),
      ),
      (
        icon: Icons.widgets_outlined,
        label: 'ServiceModule',
        onTap: () => appStack.openService(
          AppStackRoute.serviceModule,
          params: const {'moduleId': 'demo-module', 'bundleUrl': 'https://example.com/bundle.js'},
        ),
      ),
      (
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => rootNavKey.currentState?.pushNamed(SettingsScreen.routeName),
      ),
    ];

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: appStack.canGoBack ? appStack.goBack : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Expanded(
                  child: Text(
                    "N'TERI",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(onPressed: appStack.toggleMenu, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: [
                for (final item in items)
                  InkWell(
                    onTap: () {
                      appStack.toggleMenu();
                      item.onTap();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 28),
                          const SizedBox(height: 8),
                          Text(item.label, textAlign: TextAlign.center, maxLines: 2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

