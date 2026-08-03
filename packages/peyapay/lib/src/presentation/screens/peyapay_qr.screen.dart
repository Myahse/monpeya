import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/core/qr/cached_qr_view.dart';
import 'package:peyapay/src/data/models/peyapay_scanned_qr.model.dart';
import 'package:peyapay/src/data/services/peyapay_crypto.service.dart';
import 'package:peyapay/src/data/services/peyapay_qr.service.dart';
import 'package:peyapay/src/data/services/peyapay_wallet_qr.cache.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_qr_scan_overlay.widget.dart';

enum PeyapayQrMode { scan, myQr }

/// Unified PeyaPay QR hub: scan a code or show your wallet QR.
class PeyapayQrScreen extends StatefulWidget {
  const PeyapayQrScreen({super.key, this.initialMode = PeyapayQrMode.scan});

  final PeyapayQrMode initialMode;

  @override
  State<PeyapayQrScreen> createState() => _PeyapayQrScreenState();
}

class _PeyapayQrScreenState extends State<PeyapayQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final PeyapayQrService _qrService = PeyapayQrService();

  late PeyapayQrMode _mode;

  bool _isProcessingScan = false;
  bool _invalidQr = false;

  String? _myQrContent;
  String? _displayName;
  String? _myQrError;
  bool _loadingMyQr = false;
  bool _usesSecureQr = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == PeyapayQrMode.myQr) {
      _controller.stop();
      _loadMyQr();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setMode(PeyapayQrMode mode) async {
    if (_mode == mode) return;

    setState(() => _mode = mode);

    if (mode == PeyapayQrMode.scan) {
      await _controller.start();
    } else {
      await _controller.stop();
      if (_myQrContent == null && !_loadingMyQr) {
        await _loadMyQr();
      }
    }
  }

  Future<void> _loadMyQr() async {
    setState(() {
      _loadingMyQr = true;
      _myQrError = null;
    });

    try {
      final phone = await PeyapayHostBridge.requireAuth.getPhone();
      final clientState = PeyapayHostBridge.api?.clientState;
      final displayName = clientState?.nomClient?.trim();
      final phoneDigits = normalizePeyapayPhone(phone ?? '');

      if (phoneDigits.length != 10) {
        throw StateError('Numéro de téléphone invalide pour générer le QR');
      }

      final result = await _qrService.generateWalletQr(
        clientCodeKey: phoneDigits,
        displayName: displayName?.isNotEmpty == true ? displayName! : phoneDigits,
      );

      PeyapayWalletQrCache.instance.save(phone: phoneDigits, qrContent: result.qrContent);

      if (!mounted) return;
      setState(() {
        _myQrContent = result.qrContent;
        _displayName = displayName?.isNotEmpty == true ? displayName : phoneDigits;
        _usesSecureQr = _qrService.hasSecretKey;
        _loadingMyQr = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _myQrError = e.toString();
        _loadingMyQr = false;
      });
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_mode != PeyapayQrMode.scan || _isProcessingScan) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessingScan = true);

    try {
      final parsed = _qrService.parseScannedCode(rawValue);
      if (parsed == null) {
        _showInvalidQr();
        return;
      }

      await _controller.stop();
      if (!mounted) return;
      Navigator.of(context).pop<PeyapayScannedQrData>(parsed);
    } catch (_) {
      _showInvalidQr();
    }
  }

  void _showInvalidQr() {
    if (!mounted) return;
    setState(() {
      _isProcessingScan = false;
      _invalidQr = true;
    });

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _invalidQr = false);
    });
  }

  List<Widget> _buildCornerIndicators(
    double scanAreaSize,
    double scanAreaTop,
    double screenWidth,
  ) {
    const cornerLength = 28.0;
    const stroke = 4.0;
    const color = Color(0xFF006D56);
    final left = (screenWidth - scanAreaSize) / 2;
    final top = scanAreaTop;

    Widget corner({required Alignment alignment, required double x, required double y}) {
      return Positioned(
        left: x,
        top: y,
        child: IgnorePointer(
          child: SizedBox(
            width: cornerLength,
            height: cornerLength,
            child: CustomPaint(
              painter: _CornerPainter(
                color: color,
                strokeWidth: stroke,
                alignment: alignment,
              ),
            ),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft, x: left - stroke, y: top - stroke),
      corner(
        alignment: Alignment.topRight,
        x: left + scanAreaSize - cornerLength + stroke,
        y: top - stroke,
      ),
      corner(
        alignment: Alignment.bottomLeft,
        x: left - stroke,
        y: top + scanAreaSize - cornerLength + stroke,
      ),
      corner(
        alignment: Alignment.bottomRight,
        x: left + scanAreaSize - cornerLength + stroke,
        y: top + scanAreaSize - cornerLength + stroke,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanAreaSize = screenSize.width * 0.7;
    final scanAreaTop = (screenSize.height - scanAreaSize) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_mode == PeyapayQrMode.scan) ...[
            MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
              scanWindow: Rect.fromLTWH(
                (screenSize.width - scanAreaSize) / 2,
                scanAreaTop,
                scanAreaSize,
                scanAreaSize,
              ),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: PeyapayQrScanOverlayPainter(
                  scanAreaSize: scanAreaSize,
                  scanAreaTop: scanAreaTop,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: scanAreaTop,
              left: (screenSize.width - scanAreaSize) / 2,
              child: IgnorePointer(
                child: Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            ..._buildCornerIndicators(scanAreaSize, scanAreaTop, screenSize.width),
            if (_invalidQr)
              Positioned(
                left: 24,
                right: 24,
                bottom: 160,
                child: _InvalidQrBanner(),
              ),
            if (_isProcessingScan)
              IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Color(0xFF006D56)),
                ),
              ),
          ] else
            _MyQrPanel(
              loading: _loadingMyQr,
              error: _myQrError,
              displayName: _displayName,
              qrContent: _myQrContent,
              usesSecureQr: _usesSecureQr,
              onRetry: _loadMyQr,
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        _mode == PeyapayQrMode.scan
                            ? 'Scanner le QR Code'
                            : 'Mon QR Peya Pay',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_mode == PeyapayQrMode.scan)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
                        child: Text(
                          'Positionnez le QR code dans le cadre',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _ModeSwitcher(
                      mode: _mode,
                      onChanged: _setMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatefulWidget {
  const _ModeSwitcher({required this.mode, required this.onChanged});

  final PeyapayQrMode mode;
  final ValueChanged<PeyapayQrMode> onChanged;

  @override
  State<_ModeSwitcher> createState() => _ModeSwitcherState();
}

class _ModeSwitcherState extends State<_ModeSwitcher> {
  static const _modes = PeyapayQrMode.values;

  void _select(PeyapayQrMode mode) {
    if (widget.mode != mode) widget.onChanged(mode);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 120) return;
    if (velocity < 0 && widget.mode == PeyapayQrMode.scan) {
      _select(PeyapayQrMode.myQr);
    } else if (velocity > 0 && widget.mode == PeyapayQrMode.myQr) {
      _select(PeyapayQrMode.scan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.mode == PeyapayQrMode.scan ? 0 : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / _modes.length;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      left: selectedIndex * segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D56),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF006D56).withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeChip(
                            label: 'Scanner',
                            icon: Icons.qr_code_scanner_rounded,
                            selected: widget.mode == PeyapayQrMode.scan,
                            onTap: () => _select(PeyapayQrMode.scan),
                          ),
                        ),
                        Expanded(
                          child: _ModeChip(
                            label: 'Mon QR',
                            icon: Icons.qr_code_2_rounded,
                            selected: widget.mode == PeyapayQrMode.myQr,
                            onTap: () => _select(PeyapayQrMode.myQr),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyQrPanel extends StatelessWidget {
  const _MyQrPanel({
    required this.loading,
    required this.error,
    required this.displayName,
    required this.qrContent,
    required this.usesSecureQr,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final String? displayName;
  final String? qrContent;
  final bool usesSecureQr;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF006D56)),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              const Text(
                'Impossible d\'afficher le QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006D56),
                  foregroundColor: Colors.white,
                ),
                onPressed: onRetry,
                child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      );
    }

    final boxSize = size.width * 0.72;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.paddingOf(context).top + 64,
          24,
          140,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Présentez ce QR pour recevoir un paiement',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
            if (!usesSecureQr) ...[
              const SizedBox(height: 8),
              Text(
                'Configurez QR_ENCRYPT_KEY dans app/.env (32+ caractères, entre guillemets si la clé contient #).',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: boxSize,
              height: boxSize,
              child: qrContent == null
                  ? const SizedBox.shrink()
                  : CachedQRFill(
                      qrContent: qrContent!,
                      lightOnDark: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvalidQrBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ce QR code n\'est pas valide. Assurez-vous qu\'il s\'agit d\'un QR code Peya Pay.',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.alignment,
  });

  final Color color;
  final double strokeWidth;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (alignment == Alignment.topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
