import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/core/host/immo_host.bridge.dart';

/// Shared Mr Immo layout kit — the Location (rental) look, reusable by
/// Construction and Collection. Colours come from [ImmoBrand.rentalOf], so
/// wrap screens in `ImmoRentalTheme(accent: ...)` to switch the accent.
abstract final class ImmoSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

// ── Navigation ─────────────────────────────────────────────────────────────

class ImmoNavItem {
  const ImmoNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Floating pill bottom nav with a sliding selector.
class ImmoPillNavBar extends StatelessWidget {
  const ImmoPillNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ImmoNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const barHeight = 58.0;
  static const horizontalInset = 18.0;
  static const bottomGap = 10.0;

  static double layoutHeight(BuildContext context) =>
      barHeight + bottomGap + MediaQuery.viewPaddingOf(context).bottom;

  /// Bottom padding for scroll views so content clears the floating bar.
  static double contentBottomPadding(BuildContext context) =>
      layoutHeight(context) + 12;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final index = selectedIndex.clamp(0, items.length - 1);

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
                    left: index * itemWidth,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _ImmoNavButton(
                            item: items[i],
                            selected: i == index,
                            onTap: () => onSelected(i),
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

class _ImmoNavButton extends StatelessWidget {
  const _ImmoNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ImmoNavItem item;
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
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              selected ? item.selectedIcon : item.icon,
              key: ValueKey<bool>(selected),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontFamily: ImmoBrand.fontFamily,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
              fontSize: 10,
              height: 1.0,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab host: keeps visited tabs alive, shows an optional full-screen
/// overlay, and floats [ImmoPillNavBar] over the content.
class ImmoTabScaffold extends StatefulWidget {
  const ImmoTabScaffold({
    super.key,
    required this.items,
    required this.pageBuilder,
    this.overlay,
    this.index,
    this.onIndexChanged,
  });

  final List<ImmoNavItem> items;
  final Widget Function(BuildContext context, int index) pageBuilder;

  /// Full-screen page drawn above the tabs (nav hidden while shown).
  final Widget? overlay;

  /// Controlled index; when null the scaffold manages it.
  final int? index;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<ImmoTabScaffold> createState() => _ImmoTabScaffoldState();
}

class _ImmoTabScaffoldState extends State<ImmoTabScaffold> {
  int _index = 0;
  final Set<int> _visited = {0};

  int get _current => widget.index ?? _index;

  void _select(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
    widget.onIndexChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    _visited.add(_current);

    return Scaffold(
      backgroundColor: b.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _current,
              sizing: StackFit.expand,
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  _visited.contains(i)
                      ? KeyedSubtree(
                          key: ValueKey(i),
                          child: widget.pageBuilder(context, i),
                        )
                      : const SizedBox.shrink(),
              ],
            ),
          ),
          if (widget.overlay != null)
            Positioned.fill(
              child: ColoredBox(color: b.bg, child: widget.overlay),
            ),
          if (widget.overlay == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ImmoPillNavBar(
                items: widget.items,
                selectedIndex: _current,
                onSelected: _select,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Page chrome ────────────────────────────────────────────────────────────

/// Accent header + rounded content sheet — the Location home layout.
class ImmoHeaderPage extends StatelessWidget {
  const ImmoHeaderPage({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.headerExtra,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;

  /// Optional content under the title (chips, role switch…).
  final Widget? headerExtra;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: b.header,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBackdrop(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ImmoSpacing.lg,
                  top + ImmoSpacing.md,
                  ImmoSpacing.lg,
                  ImmoSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ImmoFadeSlideIn(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eyebrow,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    if (headerExtra != null) ...[
                      const SizedBox(height: ImmoSpacing.md),
                      headerExtra!,
                    ],
                  ],
                ),
              ),
            ),
            Expanded(child: ImmoSheet(child: body)),
          ],
        ),
      ),
    );
  }
}

/// Soft decorative circles behind the accent header.
class _HeaderBackdrop extends StatelessWidget {
  const _HeaderBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          right: -40,
          top: -30,
          child: _Bubble(size: 160, alpha: 0.08),
        ),
        Positioned(
          right: 60,
          bottom: -50,
          child: _Bubble(size: 110, alpha: 0.06),
        ),
        child,
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// Rounded content panel under an accent header.
class ImmoSheet extends StatelessWidget {
  const ImmoSheet({super.key, required this.child, this.radius = 28});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: ColoredBox(color: b.bg, child: child),
    );
  }
}

/// Compact accent bar for pushed pages (back + title).
class ImmoPageHeader extends StatelessWidget {
  const ImmoPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: b.header,
      padding: EdgeInsets.fromLTRB(8, top + 6, ImmoSpacing.lg, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accent header + scrolling body for secondary tabs (Messages, Paiements…).
class ImmoTabPage extends StatelessWidget {
  const ImmoTabPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: b.header,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBackdrop(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ImmoSpacing.lg,
                  top + ImmoSpacing.md,
                  ImmoSpacing.lg,
                  ImmoSpacing.lg + 4,
                ),
                child: ImmoFadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ImmoSheet(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ImmoSpacing.lg,
                    ImmoSpacing.lg,
                    ImmoSpacing.lg,
                    ImmoPillNavBar.contentBottomPadding(context),
                  ),
                  children: ImmoStagger.wrap(children),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Content blocks ─────────────────────────────────────────────────────────

class ImmoSectionTitle extends StatelessWidget {
  const ImmoSectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: b.text,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: b.primary),
              child: Text(action!,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class ImmoStat {
  const ImmoStat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

/// Row of equal-height stat cards.
class ImmoStatRow extends StatelessWidget {
  const ImmoStatRow({super.key, required this.stats});

  final List<ImmoStat> stats;

  @override
  Widget build(BuildContext context) {
    // Same height for every card, whatever the label length.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _StatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final ImmoStat stat;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ImmoDecor.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: b.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, size: 18, color: b.primary),
          ),
          const SizedBox(height: 12),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: b.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            maxLines: 2,
            style: TextStyle(fontSize: 12, color: b.muted, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class ImmoAction {
  const ImmoAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
}

/// Two-column grid of quick actions.
class ImmoActionGrid extends StatelessWidget {
  const ImmoActionGrid({super.key, required this.actions});

  final List<ImmoAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [for (final a in actions) _ActionCard(action: a)],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final ImmoAction action;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return ImmoPressable(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: ImmoDecor.card(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(action.icon, color: b.primary, size: 28),
            const Spacer(),
            Text(
              action.title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: b.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              action.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: b.muted, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

/// List row card (icon, title, subtitle, chevron).
class ImmoListTile extends StatelessWidget {
  const ImmoListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final tint = danger ? b.danger : b.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ImmoPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ImmoDecor.card(context),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: danger ? b.danger : b.text,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12.5, color: b.muted),
                      ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? Icon(Icons.chevron_right_rounded, color: b.muted)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty state with an optional action.
class ImmoEmptyState extends StatelessWidget {
  const ImmoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: ImmoDecor.card(context),
      child: Column(
        children: [
          ImmoPulse(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: b.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: b.primary, size: 30),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: b.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: b.muted, height: 1.4, fontSize: 13.5),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: b.primary,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Avatar + identity + settings list + exit — shared account tab.
class ImmoAccountView extends StatelessWidget {
  const ImmoAccountView({
    super.key,
    required this.moduleLabel,
    required this.name,
    this.phone,
    this.roleLabel,
    this.guest = false,
    this.extraTiles = const [],
  });

  final String moduleLabel;
  final String name;
  final String? phone;
  final String? roleLabel;
  final bool guest;
  final List<Widget> extraTiles;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    return ImmoTabPage(
      title: 'Profil',
      subtitle: moduleLabel,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ImmoDecor.card(context),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: b.primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: b.text,
                      ),
                    ),
                    if (phone != null && phone!.isNotEmpty)
                      Text(phone!, style: TextStyle(color: b.muted)),
                    if (roleLabel != null) ...[
                      const SizedBox(height: 6),
                      ImmoChip(label: roleLabel!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (guest)
          const ImmoEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Mode invité',
            message:
                'Connectez-vous à Mon Peya pour retrouver vos données et vos paiements.',
          ),
        if (guest) const SizedBox(height: 18),
        ...extraTiles,
        const ImmoListTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Alertes et rappels',
        ),
        const ImmoListTile(
          icon: Icons.help_outline_rounded,
          title: 'Aide & support',
          subtitle: 'FAQ, contact',
        ),
        ImmoListTile(
          icon: Icons.logout_rounded,
          title: 'Retour à Mon Peya',
          danger: true,
          onTap: () => ImmoHostBridge.exitModule(context),
        ),
      ],
    );
  }
}

/// Small rounded label.
class ImmoChip extends StatelessWidget {
  const ImmoChip({super.key, required this.label, this.onDark = false});

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.18)
            : b.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onDark ? Colors.white : b.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Segmented switch on the accent header (e.g. Fournisseur / Chef de chantier).
class ImmoHeaderSegment extends StatelessWidget {
  const ImmoHeaderSegment({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: selected * w,
                width: w,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: ImmoBrand.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: i == selected ? b.primary : Colors.white,
                            ),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

abstract final class ImmoDecor {
  static BoxDecoration card(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return BoxDecoration(
      color: b.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: b.border.withValues(alpha: b.isDark ? 1 : 0.6)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: b.isDark ? 0.3 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

// ── Motion ─────────────────────────────────────────────────────────────────

/// Fades and slides its child up once, after [delay].
class ImmoFadeSlideIn extends StatefulWidget {
  const ImmoFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<ImmoFadeSlideIn> createState() => _ImmoFadeSlideInState();
}

class _ImmoFadeSlideInState extends State<ImmoFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

abstract final class ImmoStagger {
  /// Wraps each child in [ImmoFadeSlideIn] with a growing delay.
  static List<Widget> wrap(List<Widget> children, {int stepMs = 60}) => [
        for (var i = 0; i < children.length; i++)
          ImmoFadeSlideIn(
            delay: Duration(milliseconds: 80 + i * stepMs),
            child: children[i],
          ),
      ];
}

/// Scales down slightly while pressed.
class ImmoPressable extends StatefulWidget {
  const ImmoPressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<ImmoPressable> createState() => _ImmoPressableState();
}

class _ImmoPressableState extends State<ImmoPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// Gentle breathing scale for empty-state icons.
class ImmoPulse extends StatefulWidget {
  const ImmoPulse({super.key, required this.child});

  final Widget child;

  @override
  State<ImmoPulse> createState() => _ImmoPulseState();
}

class _ImmoPulseState extends State<ImmoPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.94, end: 1.04)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
