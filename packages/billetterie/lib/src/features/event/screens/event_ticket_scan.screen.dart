import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/event/services/billetterie_event_api.service.dart';
import 'package:billetterie/src/shared/models/billetterie.ticket.dart';
import 'package:billetterie/src/shared/models/ticketing_api.exception.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

/// Scan a client event ticket QR and consume / validate it.
class EventTicketScanScreen extends StatefulWidget {
  const EventTicketScanScreen({super.key});

  @override
  State<EventTicketScanScreen> createState() => _EventTicketScanScreenState();
}

class _EventTicketScanScreenState extends State<EventTicketScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final _api = BilletterieEventApiService();

  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showResult({
    required String title,
    required String message,
    required BilletterieResultKind kind,
  }) async {
    if (!mounted) return;
    await showBilletterieResultDialog(
      context,
      title: title,
      message: message,
      kind: kind,
      brand: BilletterieBrand.eventOf(context),
      confirmLabel: kind == BilletterieResultKind.success ? 'Continuer' : 'OK',
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    setState(() => _busy = true);
    await _controller.stop();

    try {
      final client = await BilletterieHostBridge.requireClient();

      BilletterieTicket? verified;
      try {
        verified = await _api.verifyQr(raw);
      } on TicketingApiException {
        verified = null;
      }

      final purpose = verified?.purpose?.trim().toUpperCase();
      if (purpose == 'TRANSPORT') {
        await _showResult(
          title: 'Billet incorrect',
          message:
              'Ce QR est un billet transport. Utilisez le scanner événements.',
          kind: BilletterieResultKind.error,
        );
        return;
      }

      final consumed = await _api.consumeQr(
        qrPayload: raw,
        scannerCodeClient: client.codeClient,
      );

      final label = consumed.id.isNotEmpty
          ? consumed.id
          : (verified?.id.isNotEmpty == true ? verified!.id : 'événement');
      final eventHint = consumed.eventCode != null &&
              consumed.eventCode!.trim().isNotEmpty
          ? '\nÉvénement : ${consumed.eventCode}'
          : '';

      await _showResult(
        title: 'Entrée validée',
        message: 'Le billet $label a été scanné avec succès.$eventHint',
        kind: BilletterieResultKind.success,
      );
    } on TicketingApiException catch (e) {
      await _showResult(
        title: 'Validation impossible',
        message: e.message,
        kind: BilletterieResultKind.error,
      );
    } catch (e) {
      await _showResult(
        title: 'Validation impossible',
        message: '$e',
        kind: BilletterieResultKind.error,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _controller.start();
      }
    }
  }

  Rect _scanWindow(Size size) {
    final scanSize = (size.shortestSide * 0.72).clamp(220.0, 320.0);
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) * 0.38;
    return Rect.fromLTWH(left, top, scanSize, scanSize);
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner un billet'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final hole = _scanWindow(size);

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                scanWindow: hole,
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _EventQrScanOverlayPainter(hole: hole),
                  child: const SizedBox.expand(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Text(
                    _busy
                        ? 'Validation en cours…'
                        : 'Présentez le QR du billet événement dans le cadre',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              if (_busy)
                IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(color: brand.primaryDark),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EventQrScanOverlayPainter extends CustomPainter {
  _EventQrScanOverlayPainter({required this.hole});

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 22.0;
    final r = hole;
    // Top-left
    canvas.drawLine(Offset(r.left, r.top + len), Offset(r.left, r.top), cornerPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + len, r.top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(r.right - len, r.top), Offset(r.right, r.top), cornerPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + len), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - len), Offset(r.left, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + len, r.bottom), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(r.right - len, r.bottom), Offset(r.right, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - len), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _EventQrScanOverlayPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
