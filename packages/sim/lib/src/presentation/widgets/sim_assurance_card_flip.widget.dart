import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:sim/src/data/models/sim_assurance_card.model.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';

/// Carte officielle SIM (PNG API) avec interaction 3D — pas de maquette locale.
class SimAssuranceCardFlip extends StatefulWidget {
  const SimAssuranceCardFlip({
    super.key,
    required this.record,
    this.pngBytes,
    this.compact = false,
    this.frozen = false,
  });

  final SimAssuranceCardRecord record;
  final Uint8List? pngBytes;
  final bool compact;
  final bool frozen;

  @override
  State<SimAssuranceCardFlip> createState() => _SimAssuranceCardFlipState();
}

class _SimAssuranceCardFlipState extends State<SimAssuranceCardFlip> with SingleTickerProviderStateMixin {
  static const _maxHeightFull = 420.0;
  static const _maxHeightCompact = 280.0;

  late final AnimationController _flip;
  bool _isFlipped = false;
  double? _aspectRatio;
  Object? _decodedBytesIdentity;

  Uint8List? get _bytes => widget.pngBytes ?? widget.record.cartePngBytes;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scheduleAspectDecode();
  }

  @override
  void didUpdateWidget(covariant SimAssuranceCardFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pngBytes, widget.pngBytes) ||
        oldWidget.record.cartePngBase64 != widget.record.cartePngBase64) {
      _scheduleAspectDecode();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _scheduleAspectDecode() {
    final bytes = _bytes;
    if (bytes == null) {
      _decodedBytesIdentity = null;
      _aspectRatio = null;
      return;
    }
    if (identical(bytes, _decodedBytesIdentity) && _aspectRatio != null) return;
    unawaited(_decodeAspectRatio(bytes));
  }

  Future<void> _decodeAspectRatio(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final w = image.width;
      final h = image.height;
      image.dispose();
      if (w <= 0 || h <= 0 || !mounted) return;
      if (!identical(bytes, _bytes)) return;
      setState(() {
        _decodedBytesIdentity = bytes;
        _aspectRatio = w / h;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _decodedBytesIdentity = bytes;
        _aspectRatio = 1.586; // ISO ID-1 fallback
      });
    }
  }

  Future<void> _animateToSide(bool showBack) async {
    await _flip.animateTo(
      showBack ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _isFlipped = showBack);
  }

  void _toggleFlip() {
    if (_bytes == null) return;
    _animateToSide(!_isFlipped);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_bytes == null) return;
    _flip.stop();
    final delta = -d.delta.dx / 220;
    _flip.value = (_flip.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_bytes == null) return;
    final vx = d.velocity.pixelsPerSecond.dx;
    final showBack = _flip.value > 0.5 || vx < -400
        ? true
        : _flip.value < 0.5 || vx > 400
            ? false
            : _isFlipped;
    _animateToSide(showBack);
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.frozen ? 0.55 : 1.0;
    final bytes = _bytes;
    final maxHeight = widget.compact ? _maxHeightCompact : _maxHeightFull;
    final aspect = _aspectRatio ?? 1.586;

    return Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          var height = maxW / aspect;
          var width = maxW;
          if (height > maxHeight) {
            height = maxHeight;
            width = height * aspect;
          }

          return SizedBox(
            width: double.infinity,
            height: height,
            child: GestureDetector(
              onTap: _toggleFlip,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: bytes == null
                  ? _OfficialCardPlaceholder(compact: widget.compact)
                  : Center(
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: AnimatedBuilder(
                          animation: _flip,
                          builder: (context, _) {
                            final angle = _flip.value * math.pi;
                            final showFront = angle <= math.pi / 2;

                            return Stack(
                              fit: StackFit.expand,
                              alignment: Alignment.center,
                              children: [
                                _CardSide(
                                  visible: showFront,
                                  angle: angle,
                                  isFront: true,
                                  child: _OfficialCardFace(bytes: bytes, compact: widget.compact),
                                ),
                                _CardSide(
                                  visible: !showFront,
                                  angle: angle,
                                  isFront: false,
                                  child: _OfficialCardFace(bytes: bytes, compact: widget.compact),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _CardSide extends StatelessWidget {
  const _CardSide({
    required this.visible,
    required this.angle,
    required this.isFront,
    required this.child,
  });

  final bool visible;
  final double angle;
  final bool isFront;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rotation = isFront ? angle : math.pi + angle;
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0014)
      ..rotateY(rotation);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !visible,
        child: Opacity(
          opacity: visible ? 1 : 0,
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OfficialCardFace extends StatelessWidget {
  const _OfficialCardFace({required this.bytes, required this.compact});

  final Uint8List bytes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 12.0 : 14.0;
    final cacheWidth = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(640, 2048);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: compact ? 10 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          bytes,
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          cacheWidth: cacheWidth,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _OfficialCardPlaceholder extends StatelessWidget {
  const _OfficialCardPlaceholder({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 12.0 : 14.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2E8E6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: SimBrand.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Carte officielle en cours de chargement…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: SimBrand.muted,
            ),
          ),
        ],
      ),
    );
  }
}
