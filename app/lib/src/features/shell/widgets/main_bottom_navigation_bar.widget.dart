import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';

/// Mon Peya shell bottom navigation — floating pill bar with sliding selector.
class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const barHeight = 58.0;
  static const horizontalInset = 18.0;
  static const bottomGap = 10.0;
  static const brandGreen = Color(0xFF006D56);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static double layoutHeight(BuildContext context) {
    return barHeight + bottomGap + MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Extra space so tab content clears the floating pill.
  static double contentBottomPadding(BuildContext context) {
    return layoutHeight(context) + 12;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final card = isDark ? cs.surfaceContainerHigh : Colors.white;
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);

    final items = <({
      String label,
      IconData? icon,
      IconData? selectedIcon,
      Widget? child,
    })>[
      (
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        child: null,
      ),
      (
        label: 'PeyaPay',
        icon: null,
        selectedIcon: null,
        child: const PeyaPayNavBarIcon(size: 20, width: 56),
      ),
      (
        label: 'My Subs',
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt_rounded,
        child: null,
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
        color: card,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
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
                          color: brandGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _MonPeyaNavItem(
                            label: items[i].label,
                            selected: selectedIndex == i,
                            muted: muted,
                            onTap: () => onDestinationSelected(i),
                            icon: items[i].icon,
                            selectedIcon: items[i].selectedIcon,
                            child: items[i].child,
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

class _MonPeyaNavItem extends StatelessWidget {
  const _MonPeyaNavItem({
    required this.label,
    required this.selected,
    required this.muted,
    required this.onTap,
    this.icon,
    this.selectedIcon,
    this.child,
  });

  final String label;
  final bool selected;
  final Color muted;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? selectedIcon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    const active = MainBottomNavigationBar.brandGreen;
    final color = selected ? active : muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: active.withValues(alpha: 0.08),
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
                child: child ??
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        selected ? selectedIcon! : icon!,
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
