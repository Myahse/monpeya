import 'dart:math' as math;

import 'package:flutter/material.dart';

class PeyapayPartyCardData {
  const PeyapayPartyCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.badgeText,
    this.badgeBg,
    this.badgeFg,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeFg;
}

class PeyapayPartyCardsStack extends StatelessWidget {
  const PeyapayPartyCardsStack({
    super.key,
    required this.left,
    required this.right,
    required this.ink,
    required this.muted,
    this.cardBg = Colors.white,
    this.cutoutBg = const Color(0xFFEBEBEB),
    this.accent = const Color(0xFF006D56),
    this.arrowBg = Colors.white,
    this.arrowBorderColor,
    this.arrowIcon,
    this.cardsReveal,
    this.arrowFade,
    this.circleScale,
  });

  final PeyapayPartyCardData left;
  final PeyapayPartyCardData right;

  final Color ink;
  final Color muted;
  final Color cardBg;
  /// Kept for API compatibility; notches are clipped so the parent bg shows through.
  final Color cutoutBg;
  final Color accent;
  final Color arrowBg;
  final Color? arrowBorderColor;
  final IconData? arrowIcon;

  final Animation<double>? cardsReveal;
  final Animation<double>? arrowFade;
  final Animation<double>? circleScale;

  static const _cardHeight = 140.0;
  static const _cardWidthFactor = 0.42;
  /// Slightly tighter than the original 12 (still leaves the cut visible).
  static const _gap = 10.0;
  /// Bite depth (horizontal).
  static const _notchX = 20.0;
  /// Bite height (vertical) — slightly taller than deep.
  static const _notchY = 23.0;
  static const _cornerRadius = 12.0;
  static const _notchFraction = 0.49;

  @override
  Widget build(BuildContext context) {
    final arrowCircle = Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: arrowBg,
        borderRadius: BorderRadius.circular(22),
        border: arrowBorderColor == null
            ? null
            : Border.all(color: arrowBorderColor!, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Icon(arrowIcon ?? Icons.chevron_right_rounded, size: 22, color: ink),
    );

    final arrowChild =
        arrowFade == null ? arrowCircle : FadeTransition(opacity: arrowFade!, child: arrowCircle);
    final scaledArrowChild =
        circleScale == null ? arrowChild : ScaleTransition(scale: circleScale!, child: arrowChild);

    Widget buildStack(double progress) {
      final t = progress.clamp(0.0, 1.0);
      final cardOpacity = Curves.easeOut.transform(t);
      final cardScale = 0.9 + (0.1 * t);

      return LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final screenW = MediaQuery.sizeOf(context).width;
          final stackInset = (screenW - w) / 2;
          final cardWidth = w * _cardWidthFactor;
          final totalCardsWidth = (cardWidth * 2) + _gap;
          final leftX = (w - totalCardsWidth) / 2;
          final rightX = leftX + cardWidth + _gap;

          final leftEntryDx = -(leftX + stackInset + cardWidth);
          final rightEntryDx = (w - rightX - cardWidth) + stackInset + cardWidth;
          final leftDx = leftEntryDx * (1 - t);
          final rightDx = rightEntryDx * (1 - t);

          Widget animatedCard(_MiniPartyCard card, {required double x, required double dx}) {
            return Positioned(
              left: x + dx,
              top: 0,
              width: cardWidth,
              height: _cardHeight,
              child: Opacity(
                opacity: cardOpacity,
                child: Transform.scale(
                  scale: cardScale,
                  alignment: Alignment.center,
                  child: card,
                ),
              ),
            );
          }

          return SizedBox(
            height: _cardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                animatedCard(
                  _MiniPartyCard(
                    side: _MiniPartyCardSide.left,
                    cardBg: cardBg,
                    ink: ink,
                    muted: muted,
                    title: left.title,
                    subtitle: left.subtitle,
                    icon: left.icon,
                    iconColor: left.iconColor ?? ink,
                    badgeText: left.badgeText,
                    badgeBg: left.badgeBg,
                    badgeFg: left.badgeFg,
                  ),
                  x: leftX,
                  dx: leftDx,
                ),
                animatedCard(
                  _MiniPartyCard(
                    side: _MiniPartyCardSide.right,
                    cardBg: cardBg,
                    ink: ink,
                    muted: muted,
                    title: right.title,
                    subtitle: right.subtitle,
                    icon: right.icon,
                    iconColor: right.iconColor ?? ink,
                    badgeText: right.badgeText,
                    badgeBg: right.badgeBg,
                    badgeFg: right.badgeFg,
                  ),
                  x: rightX,
                  dx: rightDx,
                ),
                Positioned(
                  left: (w / 2) - 17.5,
                  top: (_cardHeight * _notchFraction) - 17.5,
                  child: scaledArrowChild,
                ),
              ],
            ),
          );
        },
      );
    }

    if (cardsReveal == null) {
      return ClipRect(clipBehavior: Clip.none, child: buildStack(1));
    }

    return ClipRect(
      clipBehavior: Clip.none,
      child: AnimatedBuilder(
        animation: cardsReveal!,
        builder: (context, _) => buildStack(cardsReveal!.value),
      ),
    );
  }
}

enum _MiniPartyCardSide { left, right }

/// Half-ellipse notch on the inner edge (taller than deep).
class _PartyCardNotchClipper extends CustomClipper<Path> {
  const _PartyCardNotchClipper({
    required this.side,
    required this.cornerRadius,
    required this.notchX,
    required this.notchY,
    required this.notchFraction,
  });

  final _MiniPartyCardSide side;
  final double cornerRadius;
  final double notchX;
  final double notchY;
  final double notchFraction;

  @override
  Path getClip(Size size) {
    final cy = size.height * notchFraction;
    final r = cornerRadius;
    final path = Path();

    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);

    if (side == _MiniPartyCardSide.left) {
      path.lineTo(size.width, cy - notchY);
      path.arcTo(
        Rect.fromCenter(
          center: Offset(size.width, cy),
          width: notchX * 2,
          height: notchY * 2,
        ),
        -math.pi / 2,
        // CCW so the arc bites INTO the card (CW arcs outside and vanishes).
        -math.pi,
        false,
      );
      path.lineTo(size.width, size.height - r);
    } else {
      path.lineTo(size.width, size.height - r);
    }

    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);

    if (side == _MiniPartyCardSide.right) {
      path.lineTo(0, cy + notchY);
      path.arcTo(
        Rect.fromCenter(
          center: Offset(0, cy),
          width: notchX * 2,
          height: notchY * 2,
        ),
        math.pi / 2,
        -math.pi,
        false,
      );
      path.lineTo(0, r);
    } else {
      path.lineTo(0, r);
    }

    path.quadraticBezierTo(0, 0, r, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _PartyCardNotchClipper oldClipper) {
    return oldClipper.side != side ||
        oldClipper.cornerRadius != cornerRadius ||
        oldClipper.notchX != notchX ||
        oldClipper.notchY != notchY ||
        oldClipper.notchFraction != notchFraction;
  }
}

class _MiniPartyCard extends StatelessWidget {
  const _MiniPartyCard({
    required this.side,
    required this.cardBg,
    required this.ink,
    required this.muted,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
  });

  final _MiniPartyCardSide side;
  final Color cardBg;
  final Color ink;
  final Color muted;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeFg;

  @override
  Widget build(BuildContext context) {
    final badge = (badgeText == null || badgeText!.trim().isEmpty)
        ? null
        : Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: (badgeBg ?? const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText!.trim(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: badgeFg ?? ink.withValues(alpha: 0.85),
                ),
              ),
            ),
          );

    return ClipPath(
      clipper: _PartyCardNotchClipper(
        side: side,
        cornerRadius: PeyapayPartyCardsStack._cornerRadius,
        notchX: PeyapayPartyCardsStack._notchX,
        notchY: PeyapayPartyCardsStack._notchY,
        notchFraction: PeyapayPartyCardsStack._notchFraction,
      ),
      child: ColoredBox(
        color: cardBg,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (badge != null) badge,
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
