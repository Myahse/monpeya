import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/services/billetterie_transport_api.service.dart';
import 'package:billetterie/src/features/transport/services/conductor_ticket.store.dart';
import 'package:billetterie/src/shared/models/billetterie.ticket.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

/// Scan a client ticket QR and consume / validate it.
class TicketScanConsumeScreen extends StatefulWidget {
  const TicketScanConsumeScreen({super.key});

  @override
  State<TicketScanConsumeScreen> createState() =>
      _TicketScanConsumeScreenState();
}

class _TicketScanConsumeScreenState extends State<TicketScanConsumeScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final _api = BilletterieTransportApiService();
  final _store = ConductorTicketStore();

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
      } catch (_) {}

      BilletterieTicket consumed;
      try {
        consumed = await _api.consumeQr(
          qrPayload: raw,
          scannerCodeClient: client.codeClient,
        );
      } catch (e) {
        // Local fallback: mark by ticket code embedded in payload.
        final code = _extractTicketCode(raw) ?? verified?.id;
        if (code != null) {
          final local = await _store.markConsumed(
            issuerCodeClient: client.codeClient,
            ticketCode: code,
            buyerName: verified?.holderName,
          );
          if (local == null) rethrow;
          await _showResult(
            title: 'Billet validé',
            message: 'Le billet $code a été validé avec succès.',
            kind: BilletterieResultKind.success,
          );
          if (mounted) {
            setState(() => _busy = false);
            await _controller.start();
          }
          return;
        }
        rethrow;
      }

      await _showResult(
        title: 'Billet validé',
        message:
            'Le billet ${consumed.id} a été validé avec succès.',
        kind: BilletterieResultKind.success,
      );
      if (mounted) {
        setState(() => _busy = false);
        await _controller.start();
      }
    } catch (e) {
      await _showResult(
        title: 'Validation impossible',
        message: '$e',
        kind: BilletterieResultKind.error,
      );
      if (mounted) {
        setState(() => _busy = false);
        await _controller.start();
      }
    }
  }

  String? _extractTicketCode(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final code = uri.queryParameters['code'] ?? uri.queryParameters['ticketCode'];
      if (code != null && code.isNotEmpty) return code;
    }
    final match = RegExp(r'TKT-[A-Za-z0-9]+').firstMatch(raw);
    return match?.group(0);
  }

  Rect _scanWindow(Size size) {
    final scanSize = (size.shortestSide * 0.72).clamp(220.0, 320.0);
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) * 0.38;
    return Rect.fromLTWH(left, top, scanSize, scanSize);
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);

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
                  painter: _QrScanOverlayPainter(hole: hole),
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
                        : 'Présentez le QR du client dans le cadre',
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
                    child: CircularProgressIndicator(color: brand.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QrScanOverlayPainter extends CustomPainter {
  _QrScanOverlayPainter({required this.hole});

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _QrScanOverlayPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
