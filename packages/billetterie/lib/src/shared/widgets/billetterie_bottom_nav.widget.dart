import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

enum BilletterieTab { home, map, tickets, profile }

/// Transport bottom navigation — floating pill bar with sliding selector.
///
/// Client: Home | Carte | Mes tickets | Profil
/// Business: Accueil | Carte | Scanner | Profil
class BilletterieBottomNav extends StatelessWidget {
  const BilletterieBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
    this.businessMode = false,
  });

  final BilletterieTab current;
  final ValueChanged<BilletterieTab> onChanged;
  final bool businessMode;

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
    final brand = BilletterieBrand.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final homeLabel = businessMode ? 'Accueil' : 'Home';
    final ticketsLabel = businessMode ? 'Scanner' : 'Mes tickets';

    final items = <({
      String label,
      IconData icon,
      IconData selectedIcon,
      BilletterieTab tab,
    })>[
      (
        label: homeLabel,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        tab: BilletterieTab.home,
      ),
      (
        label: 'Carte',
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        tab: BilletterieTab.map,
      ),
      (
        label: ticketsLabel,
        icon: businessMode
            ? Icons.qr_code_scanner_rounded
            : Icons.confirmation_number_outlined,
        selectedIcon: businessMode
            ? Icons.qr_code_scanner_rounded
            : Icons.confirmation_number_rounded,
        tab: BilletterieTab.tickets,
      ),
      (
        label: 'Profil',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        tab: BilletterieTab.profile,
      ),
    ];

    final selectedIndex =
        items.indexWhere((e) => e.tab == current).clamp(0, items.length - 1);

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
                    children: [
                      for (final item in items)
                        Expanded(
                          child: _PillNavItem(
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

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
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
    final brand = BilletterieBrand.of(context);
    final color = selected ? brand.primaryDark : brand.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: brand.primaryDark.withValues(alpha: 0.08),
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
              fontSize: 11,
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
