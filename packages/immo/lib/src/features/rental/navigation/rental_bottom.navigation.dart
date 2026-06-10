import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/navigation/rental.tab.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

/// Mirrors rental-app `BottomNavigation.tsx` — icon-only, 100px tall.
class RentalBottomNavigation extends StatelessWidget {
  const RentalBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTab,
  });

  final RentalTab activeTab;
  final ValueChanged<RentalTab> onTab;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: RentalTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: RentalTheme.bottomNavHeight - RentalTheme.bottomNavSafe,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final tab in RentalTab.values) _NavItem(
                tab: tab,
                active: tab == activeTab,
                onTap: () => onTab(tab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final RentalTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = tab == RentalTab.home ? 26.0 : 24.0;
    return Material(
      color: active ? const Color(0xFFF0F8FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RentalTheme.spacingMd,
            vertical: RentalTheme.spacingSm,
          ),
          child: Icon(
            tab.icon,
            size: size,
            color: RentalTheme.textPrimary.withValues(alpha: active ? 1 : 0.6),
          ),
        ),
      ),
    );
  }
}
