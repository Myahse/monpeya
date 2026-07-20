import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

/// Green gradient pill CTA — matches `listPropertyButton` in RN.
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

/// Section row with optional "Voir tout" pill — RN `sectionHeader`.
class RentalSectionHeader extends StatelessWidget {
  const RentalSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: RentalTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            Material(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RentalTheme.spacingMd,
                    vertical: RentalTheme.spacingSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: RentalTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '›',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: RentalTheme.textPrimary,
                        ),
                      ),
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

/// White rounded sheet overlapping green header.
class RentalWhiteSheet extends StatelessWidget {
  const RentalWhiteSheet({
    super.key,
    required this.child,
    this.topRadius = 20,
    this.topOverlap = 0,
  });

  final Widget child;
  final double topRadius;
  final double topOverlap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -topOverlap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RentalTheme.sheetWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Home header — adapts copy to landlord vs seeker profile.
class RentalHomeHeader extends StatelessWidget {
  const RentalHomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.unreadCount = 0,
    this.onNotifications,
    this.onSwitchProfile,
  });

  final String title;
  final String subtitle;
  final int unreadCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onSwitchProfile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        RentalTheme.spacingLg,
        top + RentalTheme.spacingLg,
        RentalTheme.spacingLg,
        RentalTheme.spacingMd,
      ),
      decoration: const BoxDecoration(gradient: RentalTheme.headerGradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onSwitchProfile != null)
                IconButton(
                  onPressed: onSwitchProfile,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Changer de profil',
                  icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 22),
                ),
              IconButton(
                onPressed: onNotifications,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Landlord dashboard green header — RN `greenContent`.
class RentalLandlordHeader extends StatelessWidget {
  const RentalLandlordHeader({
    super.key,
    this.unreadCount = 0,
    this.onNotifications,
    this.onSwitchProfile,
  });

  final int unreadCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onSwitchProfile;

  @override
  Widget build(BuildContext context) {
    return RentalHomeHeader(
      title: 'Tableau de bord',
      subtitle: 'Gérez vos biens & locataires',
      unreadCount: unreadCount,
      onNotifications: onNotifications,
      onSwitchProfile: onSwitchProfile,
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
          if (leading != null) leading!,
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
