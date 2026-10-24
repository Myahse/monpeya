import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

/// Section row — "Available" + bordered "See all ›" pill (home mockup).
class RentalSectionHeader extends StatelessWidget {
  const RentalSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: b.text,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: b.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: b.text.withValues(alpha: 0.85), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: b.text,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: b.text),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-height content panel under the green header (fills remaining screen).
class RentalWhiteSheet extends StatelessWidget {
  const RentalWhiteSheet({
    super.key,
    required this.child,
    this.topRadius = 28,
  });

  final Widget child;
  final double topRadius;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: b.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
          child: child,
        ),
      ),
    );
  }
}

/// Home header — matches Mr Immo rental home mockup.
class RentalHomeHeader extends StatelessWidget {
  const RentalHomeHeader({
    super.key,
    required this.userName,
    this.eyebrow = 'Mr Immo location',
    this.tagline = 'Bienvenue sur Mr Immo',
  });

  final String userName;
  final String eyebrow;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final name = userName.trim().isEmpty ? 'Guest' : userName.trim();
    final b = ImmoBrand.rentalOf(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        RentalTheme.spacingLg,
        top + RentalTheme.spacingLg,
        RentalTheme.spacingLg,
        RentalTheme.spacingXl + 8,
      ),
      color: b.header,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Welcome, $name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tagline,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline notification opt-in card on home.
class RentalHomeNotificationCard extends StatelessWidget {
  const RentalHomeNotificationCard({
    super.key,
    required this.onAllow,
    required this.onNotNow,
  });

  final VoidCallback onAllow;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        RentalTheme.spacingLg,
        RentalTheme.spacingMd,
        RentalTheme.spacingLg,
        RentalTheme.spacingSm,
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: b.isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 44,
            color: b.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get instant notifications from promising candidates, relevant insight, no spam',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: b.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onAllow,
                      style: TextButton.styleFrom(
                        foregroundColor: b.text,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Allow',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: onNotNow,
                      style: TextButton.styleFrom(
                        foregroundColor: b.text,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Not now',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Green gradient pill CTA.
class RentalGradientPillButton extends StatelessWidget {
  const RentalGradientPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.widthFactor = 0.4,
    this.gradient = RentalTheme.ctaGradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final double widthFactor;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * widthFactor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RentalTheme.spacingMd,
                  vertical: RentalTheme.spacingSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width action of a detail page (property, lease): filled in rental green, or outlined.
/// While [busy] it spins in place of its icon and does not respond.
class RentalActionButton extends StatelessWidget {
  const RentalActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    );
    Widget leading(Color spinner) => busy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: spinner),
          )
        : Icon(icon, size: 20);
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: busy ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: RentalTheme.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: leading(Colors.white),
          label: text,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: b.text,
          side: BorderSide(color: b.text, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: leading(b.text),
        label: text,
      ),
    );
  }
}

/// Opens a rental bottom sheet: card surface, 22 top corners; tall content scrolls.
Future<T?> showRentalSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ImmoBrand.rentalOf(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: builder,
  );
}

/// Handle, title and body of a rental bottom sheet. Rises above the keyboard.
class RentalSheetFrame extends StatelessWidget {
  const RentalSheetFrame({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: b.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: b.text,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Payments / messages tall gradient header.
class RentalGradientPageHeader extends StatelessWidget {
  const RentalGradientPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.paddingTop = 60,
    this.paddingBottom = 40,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final double paddingTop;
  final double paddingBottom;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        RentalTheme.spacingLg,
        top + paddingTop - 44,
        RentalTheme.spacingLg,
        paddingBottom,
      ),
      decoration: const BoxDecoration(gradient: RentalTheme.headerGradient),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xE6FFFFFF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
