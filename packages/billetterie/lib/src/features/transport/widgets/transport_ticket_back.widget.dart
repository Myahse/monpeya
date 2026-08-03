import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/shared/widgets/ticket_shape.clipper.dart';

/// Owned-ticket back — route codes, duration, and QR (Figma flip face).
///
/// Optional [qrOverlay] sits on top of the QR (scratch foil).
class TransportTicketBack extends StatelessWidget {
  const TransportTicketBack({
    super.key,
    required this.ticket,
    this.width,
    this.height,
    this.onTap,
    this.qrOverlay,
  });

  final BilletterieTransportTicket ticket;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  /// Drawn above the QR (e.g. scratch-to-reveal foil).
  final Widget? qrOverlay;

  @override
  Widget build(BuildContext context) {
    const cornerRadius = 20.0;
    const notchRadius = 10.0;
    const dividerFraction = 0.28;
    final brand = BilletterieBrand.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (width ?? constraints.maxWidth).clamp(
          280.0,
          constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0,
        );
        final cardHeight = height ?? cardWidth * 0.95;
        final textTheme = Theme.of(context).textTheme;

        final isLight = Theme.of(context).brightness == Brightness.light;
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    child: Column(
                      children: [
                        // Header tap flips back to the front (QR area keeps gestures).
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onTap,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ticket.fromCode,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: brand.ticketInk,
                                      letterSpacing: -0.4,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    ticket.toCode,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: brand.ticketInk,
                                      letterSpacing: -0.4,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ticket.durationLabel,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: brand.ticketInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  QrImageView(
                                    data: ticket.resolvedQrPayload,
                                    version: QrVersions.auto,
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: BilletterieBrand.qrInk,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape:
                                          QrDataModuleShape.square,
                                      color: BilletterieBrand.qrInk,
                                    ),
                                  ),
                                  if (qrOverlay != null) qrOverlay!,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

        return card;
      },
    );
  }
}
