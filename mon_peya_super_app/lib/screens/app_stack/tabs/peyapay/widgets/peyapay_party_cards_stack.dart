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
    this.leftSlide,
    this.rightSlide,
    this.arrowFade,
    this.circleScale,
  });

  final PeyapayPartyCardData left;
  final PeyapayPartyCardData right;

  final Color ink;
  final Color muted;
  final Color cardBg;
  final Color cutoutBg;
  final Color accent;
  final Color arrowBg;
  final Color? arrowBorderColor;
  final IconData? arrowIcon;

  final Animation<Offset>? leftSlide;
  final Animation<Offset>? rightSlide;
  final Animation<double>? arrowFade;
  final Animation<double>? circleScale;

  @override
  Widget build(BuildContext context) {
    final leftCard = _MiniPartyCard(
      side: _MiniPartyCardSide.left,
      cardBg: cardBg,
      cutoutBg: cutoutBg,
      ink: ink,
      muted: muted,
      title: left.title,
      subtitle: left.subtitle,
      icon: left.icon,
      iconColor: left.iconColor ?? ink,
      badgeText: left.badgeText,
      badgeBg: left.badgeBg,
      badgeFg: left.badgeFg,
    );

    final rightCard = _MiniPartyCard(
      side: _MiniPartyCardSide.right,
      cardBg: cardBg,
      cutoutBg: cutoutBg,
      ink: ink,
      muted: muted,
      title: right.title,
      subtitle: right.subtitle,
      icon: right.icon,
      iconColor: right.iconColor ?? ink,
      badgeText: right.badgeText,
      badgeBg: right.badgeBg,
      badgeFg: right.badgeFg,
    );

    final leftChild = leftSlide == null ? leftCard : SlideTransition(position: leftSlide!, child: leftCard);
    final rightChild = rightSlide == null ? rightCard : SlideTransition(position: rightSlide!, child: rightCard);

    final arrowCircle = Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: arrowBg,
        borderRadius: BorderRadius.circular(22),
        border: arrowBorderColor == null ? null : Border.all(color: arrowBorderColor!, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(arrowIcon ?? Icons.chevron_right_rounded, size: 22, color: ink),
    );

    final arrowChild = arrowFade == null ? arrowCircle : FadeTransition(opacity: arrowFade!, child: arrowCircle);
    final scaledArrowChild = circleScale == null ? arrowChild : ScaleTransition(scale: circleScale!, child: arrowChild);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cardWidth = w * 0.42;
        final gap = 12.0;
        final cardHeight = 140.0;
        final totalCardsWidth = (cardWidth * 2) + gap;
        final leftX = (w - totalCardsWidth) / 2;
        final rightX = leftX + cardWidth + gap;

        return SizedBox(
          height: cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: leftX, top: 0, width: cardWidth, height: cardHeight, child: leftChild),
              Positioned(left: rightX, top: 0, width: cardWidth, height: cardHeight, child: rightChild),
              Positioned(
                left: (w / 2) - 17.5,
                top: (cardHeight * 0.49) - 17.5,
                child: scaledArrowChild,
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _MiniPartyCardSide { left, right }

class _MiniPartyCard extends StatelessWidget {
  const _MiniPartyCard({
    required this.side,
    required this.cardBg,
    required this.cutoutBg,
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
  final Color cutoutBg;
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
    final cutout = Positioned(
      top: (140 * 0.40) - 21,
      left: side == _MiniPartyCardSide.right ? -28 : null,
      right: side == _MiniPartyCardSide.left ? -28 : null,
      child: Container(
        width: 34,
        height: 42,
        decoration: BoxDecoration(
          color: cutoutBg,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );

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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          cutout,
          if (badge != null) badge,
          Center(
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

