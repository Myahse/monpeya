import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/features/transport/services/ticket_qr_reveal.store.dart';
import 'package:billetterie/src/shared/widgets/ticket_scratch_overlay.widget.dart';
import 'package:billetterie/src/features/transport/widgets/transport_ticket_back.widget.dart';
import 'package:billetterie/src/features/transport/widgets/transport_ticket_front.widget.dart';

/// Owned ticket: expand on first tap, flip to QR back on next tap.
///
/// QR starts behind scratch foil until revealed once (persisted).
class OwnedTransportTicket extends StatefulWidget {
  const OwnedTransportTicket({
    super.key,
    required this.ticket,
    required this.expanded,
    required this.showingBack,
    required this.onTap,
    this.badge,
    this.revealRevision = 0,
  });

  final BilletterieTransportTicket ticket;
  final BilletterieTicketBadge? badge;
  final bool expanded;
  final bool showingBack;
  final VoidCallback onTap;

  /// Bump when returning from details so scratch state reloads.
  final int revealRevision;

  @override
  State<OwnedTransportTicket> createState() => _OwnedTransportTicketState();
}

class _OwnedTransportTicketState extends State<OwnedTransportTicket>
    with SingleTickerProviderStateMixin {
  static const _flipDuration = Duration(milliseconds: 420);

  final _qrRevealStore = TicketQrRevealStore();

  late final AnimationController _flipController;
  bool _qrRevealed = false;
  bool _qrRevealLoaded = false;

  TicketQrRevealMode get _revealMode {
    // Foil until we know it was already scratched (avoids flashing the QR).
    if (!_qrRevealLoaded || !_qrRevealed) {
      return TicketQrRevealMode.scratchable;
    }
    return TicketQrRevealMode.revealed;
  }

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: _flipDuration)
      ..addListener(() => setState(() {}));
    if (widget.showingBack) _flipController.value = 1;
    _loadQrRevealState();
  }

  Future<void> _loadQrRevealState() async {
    final revealed = await _qrRevealStore.isRevealed(widget.ticket);
    if (!mounted) return;
    setState(() {
      _qrRevealed = revealed;
      _qrRevealLoaded = true;
    });
  }

  Future<void> _onQrFullyRevealed() async {
    if (_qrRevealed) return;
    setState(() => _qrRevealed = true);
    await _qrRevealStore.markRevealed(widget.ticket);
  }

  @override
  void didUpdateWidget(covariant OwnedTransportTicket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revealRevision != widget.revealRevision ||
        oldWidget.ticket.ticketCode != widget.ticket.ticketCode ||
        oldWidget.ticket.resolvedQrPayload != widget.ticket.resolvedQrPayload) {
      _qrRevealLoaded = false;
      _loadQrRevealState();
    }
    // Re-check after returning from details (may have scratched there).
    if (widget.showingBack && !oldWidget.showingBack) {
      _loadQrRevealState();
    }
    if (oldWidget.showingBack == widget.showingBack) return;
    if (widget.showingBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOutCubic.transform(_flipController.value);
    final angle = t * math.pi;
    final showBackFace = angle > math.pi / 2;
    final flipping = _flipController.isAnimating;
    final frontExpanded = widget.expanded || widget.showingBack || flipping;

    return AnimatedSize(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final backHeight = width * 0.95;

          final Widget face;
          if (showBackFace) {
            // Header tap flips; QR area keeps scratch gestures.
            face = TransportTicketBack(
              ticket: widget.ticket,
              width: width,
              height: backHeight,
              onTap: widget.onTap,
              qrOverlay: TicketScratchOverlay(
                mode: _revealMode,
                onFullyRevealed: _onQrFullyRevealed,
              ),
            );
          } else {
            face = GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: TransportTicketFront(
                ticket: widget.ticket,
                badge: widget.badge,
                width: width,
                expanded: frontExpanded,
              ),
            );
          }

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showBackFace
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: face,
                  )
                : face,
          );
        },
      ),
    );
  }
}
