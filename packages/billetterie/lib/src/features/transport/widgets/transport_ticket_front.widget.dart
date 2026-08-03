import 'package:flutter/material.dart';

import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/shared/widgets/ticket_shape.clipper.dart';

/// Transport ticket card — collapses by default, expands smoothly on tap.
/// Typography follows Mon Peya Material 3 [ThemeData.textTheme] (+ app 0.90 scale).
class TransportTicketFront extends StatelessWidget {
  const TransportTicketFront({
    super.key,
    required this.ticket,
    this.badge,
    this.width,
    this.expanded = false,
    this.onTap,
  });

  final BilletterieTransportTicket ticket;

  /// Optional badge (e.g. cheapest / cheapest & fastest), computed per list.
  final BilletterieTicketBadge? badge;

  final double? width;
  final bool expanded;
  final VoidCallback? onTap;

  static const _chipBlueStart = Color(0xFF2563EB);
  static const _chipBlueEnd = Color(0xFF1D4ED8);
  static const _chipRedStart = Color(0xFFEF4444);
  static const _chipRedEnd = Color(0xFFB91C1C);

  static const _animDuration = Duration(milliseconds: 340);
  static const _animCurve = Curves.easeInOutCubic;

  /// Compact list heights (width ratios).
  static const collapsedHeightRatio = 0.48;
  static const expandedHeightRatio = 0.70;
  static const _collapsedDivider = 0.56;
  static const _expandedDivider = 0.66;

  /// Height reserved when the card is fully expanded for [width].
  static double expandedHeightFor(double width) => width * expandedHeightRatio;

  @override
  Widget build(BuildContext context) {
    const cornerRadius = 20.0;
    const notchRadius = 10.0;
    final brand = BilletterieBrand.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (width ?? constraints.maxWidth).clamp(
          280.0,
          constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0,
        );

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: expanded ? 1 : 0),
          duration: _animDuration,
          curve: _animCurve,
          builder: (context, t, _) {
            final cardHeight = cardWidth *
                (collapsedHeightRatio +
                    (expandedHeightRatio - collapsedHeightRatio) * t);
            final dividerFraction = _collapsedDivider +
                (_expandedDivider - _collapsedDivider) * t;
            final topFlex = (56 + 10 * t).round().clamp(56, 66);
            final bottomFlex = 100 - topFlex;

            final isLight =
                Theme.of(context).brightness == Brightness.light;
            final card = SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipPath(
                    clipper: TicketShapeClipper(
                      cornerRadius: cornerRadius,
                      notchRadius: notchRadius,
                      dividerFraction: dividerFraction,
                    ),
                    child: ColoredBox(
                      color: brand.ticketBg,
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                flex: topFlex,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    16,
                                    12 - t,
                                    16,
                                    6,
                                  ),
                                  child: _TopSection(
                                    ticket: ticket,
                                    badge: badge,
                                    expandProgress: t,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: bottomFlex,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 8, 14, 10),
                                  child: _BottomSection(ticket: ticket),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: notchRadius,
                            right: notchRadius,
                            top: cardHeight * dividerFraction,
                            child: CustomPaint(
                              size: Size(cardWidth - notchRadius * 2, 1),
                              painter: _DashedLinePainter(
                                color: brand.ticketDivider,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isLight)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: TicketShapeBorderPainter(
                          cornerRadius: cornerRadius,
                          notchRadius: notchRadius,
                          dividerFraction: dividerFraction,
                          color: brand.border,
                          strokeWidth: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
            );

            return Material(
              color: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(cornerRadius),
                child: card,
              ),
            );
          },
        );
      },
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({
    required this.ticket,
    required this.badge,
    required this.expandProgress,
  });

  final BilletterieTransportTicket ticket;
  final BilletterieTicketBadge? badge;
  final double expandProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brand = BilletterieBrand.of(context);

    return Column(
      children: [
        ClipRect(
          child: Align(
            heightFactor: expandProgress,
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: expandProgress.clamp(0.0, 1.0),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _RouteHeaderIcon(),
              ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RouteCodeBlock(code: ticket.fromCode)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                ticket.durationLabel,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: brand.ticketInk,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Expanded(child: _RouteCodeBlock(code: ticket.toCode, alignEnd: true)),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _ScheduleBlock(city: ticket.fromCity, time: ticket.fromTime),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              _PriceBadge(badge: badge!),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: _ScheduleBlock(
                city: ticket.toCity,
                time: ticket.toTime,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteHeaderIcon extends StatelessWidget {
  const _RouteHeaderIcon();

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              width: 3,
              height: 3,
              margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
              decoration: BoxDecoration(
                color: brand.ticketDivider,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 1.2,
                color: const Color(0xFFE2E8F0),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: brand.ticketBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 18,
                  color: brand.ticketInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteCodeBlock extends StatelessWidget {
  const _RouteCodeBlock({required this.code, this.alignEnd = false});

  final String code;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      code,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: BilletterieBrand.of(context).ticketInk,
        letterSpacing: -0.4,
        height: 1,
      ),
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  const _ScheduleBlock({
    required this.city,
    required this.time,
    this.alignEnd = false,
  });

  final String city;
  final String time;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: BilletterieBrand.of(context).ticketInk,
        );

    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(city, style: style),
        const SizedBox(height: 1),
        Text(time, style: style),
      ],
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.badge});

  final BilletterieTicketBadge badge;

  @override
  Widget build(BuildContext context) {
    final isRed = badge.kind == BilletterieTicketBadgeKind.cheaperFaster;
    final colors = isRed
        ? const [
            TransportTicketFront._chipRedStart,
            TransportTicketFront._chipRedEnd,
          ]
        : const [
            TransportTicketFront._chipBlueStart,
            TransportTicketFront._chipBlueEnd,
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badge.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({required this.ticket});

  final BilletterieTransportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brand = BilletterieBrand.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _VehicleAvatar(imageUrl: ticket.vehicleImageUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Numéro véhicule',
                style: textTheme.labelSmall?.copyWith(
                  color: brand.ticketLabel,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                ticket.vehicleNumber,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: brand.ticketInk,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        _PriceDisplay(amount: ticket.price, currency: ticket.currency),
      ],
    );
  }
}

class _VehicleAvatar extends StatelessWidget {
  const _VehicleAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFE5E7EB),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Icon(Icons.directions_bus_filled, color: brand.ticketLabel, size: 16)
          : null,
    );
  }
}

class _PriceDisplay extends StatelessWidget {
  const _PriceDisplay({required this.amount, required this.currency});

  final int amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brand = BilletterieBrand.of(context);
    final formatted = _formatAmount(amount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatted,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: brand.ticketInk,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, left: 2),
          child: Text(
            currency,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: brand.ticketInk,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
