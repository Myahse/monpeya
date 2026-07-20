import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/services/billetterie_transport_api.service.dart';
import 'package:billetterie/src/features/transport/services/conductor_ticket.store.dart';
import 'package:billetterie/src/shared/models/billetterie.ticket.dart';

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
  String? _lastMessage;
  bool _lastOk = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    setState(() {
      _busy = true;
      _lastMessage = null;
    });
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
          if (!mounted) return;
          setState(() {
            _lastOk = true;
            _lastMessage =
                'Billet $code validé (local). Statut : ${local.status}';
            _busy = false;
          });
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) await _controller.start();
          return;
        }
        rethrow;
      }

      if (!mounted) return;
      setState(() {
        _lastOk = true;
        _lastMessage =
            'Billet ${consumed.id} validé. Statut : ${consumed.status ?? 'CONSUMED'}';
        _busy = false;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) await _controller.start();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastOk = false;
        _lastMessage = '$e';
        _busy = false;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) await _controller.start();
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              color: Colors.black54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _busy
                        ? 'Validation en cours…'
                        : 'Présentez le QR du client dans le cadre',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (_lastMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _lastMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _lastOk ? brand.primary : Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
