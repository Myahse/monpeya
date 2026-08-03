import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/navigation/rental.tab.dart';

/// Floating pill bottom nav with sliding selector — same pattern as Billetterie.
class RentalBottomNavigation extends StatelessWidget {
  const RentalBottomNavigation({
    super.key,
    required this.current,
    required this.tabs,
    required this.onChanged,
  });

  final RentalTab current;
  final List<RentalTab> tabs;
  final ValueChanged<RentalTab> onChanged;

  static const barHeight = 58.0;
  static const horizontalInset = 18.0;
  static const bottomGap = 10.0;

  static double layoutHeight(BuildContext context) {
    return barHeight + bottomGap + MediaQuery.viewPaddingOf(context).bottom;
  }

  static double contentBottomPadding(BuildContext context) {
    return layoutHeight(context) + 12;
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final items = tabs.isEmpty ? RentalTab.clientTabs : tabs;
    final selectedIndex = items.indexOf(current).clamp(0, items.length - 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        bottomGap + bottomInset,
      ),
      child: Material(
        color: b.card,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: b.border),
          ),
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * itemWidth,
                    top: 0,
                    width: itemWidth,
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: b.primaryDark.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final tab in items)
                        Expanded(
                          child: _RentalNavItem(
                            label: tab.label,
                            icon: tab.icon,
                            selectedIcon: tab.selectedIcon,
                            selected: current == tab,
                            onTap: () => onChanged(tab),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RentalNavItem extends StatelessWidget {
  const _RentalNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final color = selected ? b.primaryDark : b.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: b.primaryDark.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Icon(
              selected ? selectedIcon : icon,
              key: ValueKey<bool>(selected),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
              fontSize: 10,
              height: 1.0,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
