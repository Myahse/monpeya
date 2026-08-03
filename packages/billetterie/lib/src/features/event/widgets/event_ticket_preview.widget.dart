import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/event/models/event_ticket_layout.dart';
import 'package:billetterie/src/shared/widgets/ticket_shape.clipper.dart';

/// Live preview of an event ticket in [horizontal] or [square] layout.
class EventTicketPreview extends StatelessWidget {
  const EventTicketPreview({
    super.key,
    required this.layout,
    required this.title,
    required this.venue,
    required this.dateLabel,
    required this.priceLabel,
    this.selected = false,
    this.width = 280,
  });

  final EventTicketLayout layout;
  final String title;
  final String venue;
  final String dateLabel;
  final String priceLabel;
  final bool selected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final height = width * layout.heightRatio;
    final corner = layout == EventTicketLayout.horizontal ? 14.0 : 18.0;
    final notch = layout == EventTicketLayout.horizontal ? 9.0 : 11.0;
    final divider = layout == EventTicketLayout.horizontal ? 0.62 : 0.58;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(corner + 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.22 : 0.10),
            blurRadius: selected ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: TicketShapeClipper(
              cornerRadius: corner,
              notchRadius: notch,
              dividerFraction: divider,
            ),
            child: ColoredBox(
              color: brand.primaryDark,
              child: layout == EventTicketLayout.horizontal
                  ? _HorizontalFace(
                      brand: brand,
                      title: title,
                      venue: venue,
                      dateLabel: dateLabel,
                      priceLabel: priceLabel,
                      divider: divider,
                    )
                  : _SquareFace(
                      brand: brand,
                      title: title,
                      venue: venue,
                      dateLabel: dateLabel,
                      priceLabel: priceLabel,
                      divider: divider,
                    ),
            ),
          ),
          CustomPaint(
            painter: TicketShapeBorderPainter(
              cornerRadius: corner,
              notchRadius: notch,
              dividerFraction: divider,
              color: Colors.white.withValues(alpha: 0.35),
              strokeWidth: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalFace extends StatelessWidget {
  const _HorizontalFace({
    required this.brand,
    required this.title,
    required this.venue,
    required this.dateLabel,
    required this.priceLabel,
    required this.divider,
  });

  final BilletterieBrand brand;
  final String title;
  final String venue;
  final String dateLabel;
  final String priceLabel;
  final double divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: ((divider * 100).round()).clamp(1, 99),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BILLET ÉVÉNEMENT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  title.isEmpty ? 'Nom de l’événement' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  venue.isEmpty ? 'Lieu' : venue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: (((1 - divider) * 100).round()).clamp(1, 99),
          child: Container(
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateLabel.isEmpty ? 'Date · heure' : dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  priceLabel.isEmpty ? '— FCFA' : priceLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SquareFace extends StatelessWidget {
  const _SquareFace({
    required this.brand,
    required this.title,
    required this.venue,
    required this.dateLabel,
    required this.priceLabel,
    required this.divider,
  });

  final BilletterieBrand brand;
  final String title;
  final String venue;
  final String dateLabel;
  final String priceLabel;
  final double divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: ((divider * 100).round()).clamp(1, 99),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Column(
              children: [
                Text(
                  title.isEmpty ? 'Nom de l’événement' : title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  venue.isEmpty ? 'Lieu' : venue,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 48,
                    color: brand.primaryDark,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: (((1 - divider) * 100).round()).clamp(1, 99),
          child: Container(
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateLabel.isEmpty ? 'Date · heure' : dateLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  priceLabel.isEmpty ? '— FCFA' : priceLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
