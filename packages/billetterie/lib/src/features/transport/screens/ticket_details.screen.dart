import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/features/transport/services/billetterie_notification.store.dart';
import 'package:billetterie/src/features/transport/services/billetterie_transport_api.service.dart';
import 'package:billetterie/src/features/transport/services/conductor_ticket.store.dart';
import 'package:billetterie/src/features/transport/services/ticket_pdf.service.dart';
import 'package:billetterie/src/features/transport/services/ticket_qr_reveal.store.dart';
import 'package:billetterie/src/features/transport/widgets/transport_ticket_back.widget.dart';
import 'package:billetterie/src/features/transport/widgets/transport_ticket_front.widget.dart';
import 'package:billetterie/src/shared/services/billetterie_host.payment.dart';
import 'package:billetterie/src/shared/utils/ticket_format.util.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';
import 'package:billetterie/src/shared/widgets/ticket_scratch_overlay.widget.dart';

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({
    super.key,
    required this.ticket,
    this.badge,
    this.owned = false,
  });

  final BilletterieTransportTicket ticket;
  final BilletterieTicketBadge? badge;
  final bool owned;

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const _flipDuration = Duration(milliseconds: 420);
  static const _backHeightRatio = 0.95;

  final _qrRevealStore = TicketQrRevealStore();

  bool _ticketExpanded = false;
  bool _showingBack = false;
  bool _qrRevealed = false;
  bool _qrRevealLoaded = false;

  late final AnimationController _flipController;

  bool get _showPayButton =>
      !widget.owned &&
      (widget.ticket.status == null || widget.ticket.status == 'FOR_SALE');

  TicketQrRevealMode get _revealMode {
    if (widget.owned) {
      // Foil until we know it was already scratched (avoids flashing the QR).
      if (!_qrRevealLoaded || !_qrRevealed) {
        return TicketQrRevealMode.scratchable;
      }
      return TicketQrRevealMode.revealed;
    }
    return TicketQrRevealMode.locked;
  }

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: _flipDuration)
      ..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _ticketExpanded = true);
    });
    if (widget.owned) {
      _loadQrRevealState();
    } else {
      _qrRevealLoaded = true;
    }
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
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _onTicketTap() {
    if (!_ticketExpanded || _flipController.isAnimating) return;
    setState(() => _showingBack = !_showingBack);
    if (_showingBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brand = BilletterieBrand.of(context);
    final ticket = widget.ticket;
    final badge = widget.badge;

    final flipT = Curves.easeInOutCubic.transform(_flipController.value);
    final angle = flipT * math.pi;
    final showBackFace = angle > math.pi / 2;

    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        backgroundColor: brand.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: brand.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'D?tails du ticket',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: brand.text,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed slot = back height so Trajet / Payer never shift on flip.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final slotHeight = width * _backHeightRatio;
                  final frontExpanded = _ticketExpanded ||
                      _showingBack ||
                      _flipController.isAnimating;

                  final Widget face;
                  if (showBackFace) {
                    face = TransportTicketBack(
                      ticket: ticket,
                      width: width,
                      height: slotHeight,
                      onTap: _onTicketTap,
                      qrOverlay: TicketScratchOverlay(
                        mode: _revealMode,
                        onLockedTap: _onTicketTap,
                        onFullyRevealed: _onQrFullyRevealed,
                      ),
                    );
                  } else {
                    face = TransportTicketFront(
                      ticket: ticket,
                      badge: badge,
                      width: width,
                      expanded: frontExpanded,
                      onTap: _onTicketTap,
                    );
                  }

                  return SizedBox(
                    width: width,
                    height: slotHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Transform(
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
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _showingBack
                    ? (widget.owned
                        ? (_qrRevealed
                            ? 'Touchez pour revenir ? l?avant'
                            : 'Grattez le QR ? touchez hors du QR pour revenir')
                        : 'QR verrouill? ? achetez pour gratter')
                    : 'Touchez le billet pour le retourner',
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: brand.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailSection(
                      title: 'Trajet',
                      rows: [
                        if (ticket.title != null) ('Ligne', ticket.title!),
                        if (ticket.place != null)
                          ('Point de d?part', ticket.place!),
                        if (ticket.validFrom != null)
                          (
                            'D?part',
                            formatTicketDateTime(ticket.validFrom!),
                          ),
                        if (ticket.validUntil != null)
                          (
                            'Arriv?e',
                            formatTicketDateTime(ticket.validUntil!),
                          ),
                        ('Dur?e', ticket.durationLabel),
                      ],
                    ),
                    _DetailSection(
                      title: 'V?hicule & chauffeur',
                      rows: [
                        if (ticket.vehicleType != null)
                          (
                            'Type de v?hicule',
                            ticketVehicleTypeLabel(ticket.vehicleType!),
                          ),
                        ('Immatriculation', ticket.vehicleNumber),
                        if (ticket.driverName != null)
                          ('Chauffeur', ticket.driverName!),
                        if (ticket.driverPhone != null)
                          ('T?l?phone', ticket.driverPhone!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.owned || _showPayButton)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: brand.bg,
                  border: Border(top: BorderSide(color: brand.border)),
                ),
                child: widget.owned
                    ? _ExportPdfButton(ticket: ticket)
                    : _PayTicketButton(ticket: ticket, badge: badge),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayTicketButton extends StatefulWidget {
  const _PayTicketButton({required this.ticket, this.badge});

  final BilletterieTransportTicket ticket;
  final BilletterieTicketBadge? badge;

  @override
  State<_PayTicketButton> createState() => _PayTicketButtonState();
}

class _PayTicketButtonState extends State<_PayTicketButton> {
  bool _paying = false;
  bool _isGuest = true;
  final _api = BilletterieTransportApiService();
  final _localTickets = ConductorTicketStore();

  @override
  void initState() {
    super.initState();
    _loadGuestFlag();
  }

  Future<void> _loadGuestFlag() async {
    final guest = await BilletterieHostBridge.isGuest();
    if (!mounted) return;
    setState(() => _isGuest = guest);
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final ticket = widget.ticket;
      final ticketCode = ticket.ticketCode?.trim();
      if (ticketCode == null || ticketCode.isEmpty) {
        throw StateError('Code billet manquant');
      }

      final loggedIn = await BilletterieHostBridge.ensureLoggedIn(context);
      if (!mounted) return;
      if (!loggedIn) return;

      // Subscription / registration gate after login.
      final ready = await BilletterieHostBridge.ensureReadyToPurchase(
        context,
        moduleKey: 'billetterie',
      );
      if (!mounted) return;
      if (!ready) return;

      final client = await BilletterieHostBridge.requireClient();

      final routeLabel = ticket.title?.trim().isNotEmpty == true
          ? ticket.title!.trim()
          : '${ticket.fromCity} -> ${ticket.toCity}';
      final ok = await BilletterieHostPayment.requestPayment(
        context: context,
        amount: ticket.price,
        recipientName: 'Billetterie',
        label: routeLabel,
        reference: ticketCode,
      );
      if (!mounted) return;
      if (!ok) {
        await showBilletterieResultDialog(
          context,
          title: 'Paiement annulé',
          message: 'Le paiement a été annulé. Aucun billet n’a été acheté.',
          kind: BilletterieResultKind.info,
        );
        return;
      }

      BilletterieTransportTicket? ownedTicket;
      String? orderRef;

      try {
        final purchased = await _api.buyTicket(
          ticketCode: ticketCode,
          codeClient: client.codeClient,
          buyerName: client.displayName,
          buyerPhone: client.phone,
        );
        orderRef = purchased.orderRef;
        try {
          final fresh = await _api.getTicket(purchased.id);
          ownedTicket = transportTicketFromApiJson({
            'ticketCode': fresh.id,
            'purpose': fresh.purpose ?? 'TRANSPORT',
            'title': fresh.typeName,
            'qrPayload': fresh.qrPayload,
            'status': fresh.status,
            'price': fresh.amount,
            'amountPaid': fresh.amount,
            'orderRef': fresh.orderRef ?? purchased.orderRef,
            'buyerName': fresh.holderName,
            'buyerPhone': fresh.holderPhone,
            'vehicleNumber': ticket.vehicleNumber,
            'vehicleType': ticket.vehicleType,
            'driverName': ticket.driverName,
            'driverPhone': ticket.driverPhone,
            'validFrom': ticket.validFrom?.toIso8601String(),
            'validUntil': ticket.validUntil?.toIso8601String(),
            'place': ticket.place,
            'ticketType': ticket.ticketType,
            'preOrder': ticket.preOrder,
            'builtByName': ticket.builtByName,
            'purchasedAt': fresh.createdAt,
            'fromCity': ticket.fromCity,
            'toCity': ticket.toCity,
          });
        } catch (_) {
          ownedTicket = null;
        }
        ownedTicket ??= transportTicketFromApiJson({
              'ticketCode': purchased.id,
              'purpose': purchased.purpose ?? 'TRANSPORT',
              'title': purchased.typeName,
              'qrPayload': purchased.qrPayload,
              'status': purchased.status,
              'price': purchased.amount,
              'amountPaid': purchased.amount,
              'orderRef': purchased.orderRef,
              'buyerName': purchased.holderName,
              'buyerPhone': purchased.holderPhone,
              'vehicleNumber': ticket.vehicleNumber,
              'vehicleType': ticket.vehicleType,
              'driverName': ticket.driverName,
              'driverPhone': ticket.driverPhone,
              'validFrom': ticket.validFrom?.toIso8601String(),
              'validUntil': ticket.validUntil?.toIso8601String(),
              'place': ticket.place,
              'ticketType': ticket.ticketType,
              'preOrder': ticket.preOrder,
              'builtByName': ticket.builtByName,
              'purchasedAt': purchased.createdAt,
              'fromCity': ticket.fromCity,
              'toCity': ticket.toCity,
            }) ??
            ticket;
      } catch (_) {
        // Local generate / offline: mark sold in conductor store.
        ownedTicket = await _localTickets.markSold(
          ticketCode: ticketCode,
          buyerCodeClient: client.codeClient,
          buyerName: client.resolvedDisplayName,
          buyerPhone: client.phone,
          amountPaid: ticket.price,
        );
        if (ownedTicket == null) {
          throw StateError(
            'Achat impossible ? billet introuvable c?t? serveur et en local',
          );
        }
        orderRef = ownedTicket.orderRef;
      }

      if (!mounted) return;

      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();

      await BilletterieNotificationStore().notifyTicketPurchased(
        ticketCode: ownedTicket.ticketCode ?? ticketCode,
        orderRef: orderRef,
        routeLabel: routeLabel,
      );

      await showTicketPurchaseSuccessDialog(
        context,
        orderRef: orderRef,
        routeLabel: routeLabel,
      );
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TicketDetailsScreen(
            ticket: ownedTicket!,
            badge: widget.badge,
            owned: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        await HapticFeedback.heavyImpact();
        await showTicketPurchaseErrorDialog(
          context,
          message: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    return _GradientActionButton(
      label: _paying
          ? 'Paiement…'
          : _isGuest
              ? 'Se connecter pour payer · ${ticket.price} ${ticket.currency}'
              : 'Payer · ${ticket.price} ${ticket.currency}',
      icon: _paying
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.payments_rounded,
              size: 20,
              color: Colors.white,
            ),
      onPressed: _paying ? null : _pay,
    );
  }
}

class _ExportPdfButton extends StatefulWidget {
  const _ExportPdfButton({required this.ticket});

  final BilletterieTransportTicket ticket;

  @override
  State<_ExportPdfButton> createState() => _ExportPdfButtonState();
}

class _ExportPdfButtonState extends State<_ExportPdfButton> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await TicketPdfService().exportAndShare(widget.ticket);
    } catch (e) {
      if (mounted) {
        await showBilletterieResultDialog(
          context,
          title: 'Export impossible',
          message: 'Impossible d’exporter le PDF.\n$e',
          kind: BilletterieResultKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GradientActionButton(
      label: _exporting ? 'Export en cours?' : 'Exporter en PDF',
      icon: _exporting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.picture_as_pdf_rounded,
              size: 20,
              color: Colors.white,
            ),
      onPressed: _exporting ? null : _export,
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? _gradient : null,
            color: enabled ? null : const Color(0xFF94A3B8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brand = BilletterieBrand.of(context);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: brand.text,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: brand.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brand.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 14,
                      endIndent: 14,
                      color: brand.border,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            rows[i].$1,
                            style: textTheme.bodySmall?.copyWith(
                              color: brand.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            rows[i].$2,
                            textAlign: TextAlign.end,
                            style: textTheme.bodySmall?.copyWith(
                              color: brand.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
