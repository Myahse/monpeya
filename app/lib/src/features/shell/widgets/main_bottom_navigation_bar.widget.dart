import 'package:flutter/material.dart';

/// Shared main shell bottom navigation — compact height.
class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const barHeight = 58.0;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: barHeight,
      selectedIndex: selectedIndex,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'HOME'),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'PEYAPAY',
        ),
        NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'MY SUBS'),
      ],
    );
  }
}
