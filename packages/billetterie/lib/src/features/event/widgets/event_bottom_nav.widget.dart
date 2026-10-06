import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

enum BilletterieEventTab { home, map, tickets, profile }

/// Event-module bottom navigation — floating pill bar with sliding selector.
class BilletterieEventBottomNav extends StatelessWidget {
  const BilletterieEventBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final BilletterieEventTab current;
  final ValueChanged<BilletterieEventTab> onChanged;

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
    final brand = BilletterieBrand.eventOf(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final selectedIndex = current.index;

    final items = <({
      String label,
      IconData icon,
      IconData selectedIcon,
      BilletterieEventTab tab,
    })>[
      (
        label: 'Accueil',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        tab: BilletterieEventTab.home,
      ),
      (
        label: 'Carte',
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        tab: BilletterieEventTab.map,
      ),
      (
        label: 'Tickets',
        icon: Icons.confirmation_number_outlined,
        selectedIcon: Icons.confirmation_number_rounded,
        tab: BilletterieEventTab.tickets,
      ),
      (
        label: 'Profil',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        tab: BilletterieEventTab.profile,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        bottomGap + bottomInset,
      ),
      child: Material(
        color: brand.card,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: brand.border),
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
                          color: brand.primaryDark.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items)
                        Expanded(
                          child: _EventNavItem(
                            label: item.label,
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            selected: current == item.tab,
                            onTap: () => onChanged(item.tab),
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

class _EventNavItem extends StatelessWidget {
  const _EventNavItem({
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
    final brand = BilletterieBrand.eventOf(context);
    final color = selected ? brand.primaryDark : brand.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: brand.primaryDark.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
              width: double.infinity,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    key: ValueKey<bool>(selected),
                    size: 20,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
                fontSize: 11,
                height: 1.0,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
