import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Flippable prepaid card — front = recto art, back = verso art.
/// Same tap / swipe flip as the Source of Funds debit preview.
class PeyapayPrepaidCardFlip extends StatefulWidget {
  const PeyapayPrepaidCardFlip({
    super.key,
    this.frozen = false,
  });

  final bool frozen;

  @override
  State<PeyapayPrepaidCardFlip> createState() => _PeyapayPrepaidCardFlipState();
}

class _PeyapayPrepaidCardFlipState extends State<PeyapayPrepaidCardFlip>
    with SingleTickerProviderStateMixin {
  static const _aspect = 376 / 237;

  late final AnimationController _flip;
  bool _isFlipped = false;

  static const _frontAsset = AssetImage(
    'assets/logo/cards/recto-carte-peya-pay.png',
    package: 'peyapay',
  );
  static const _backAsset = AssetImage(
    'assets/logo/cards/verso.png',
    package: 'peyapay',
  );

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_frontAsset, context);
    precacheImage(_backAsset, context);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Future<void> _animateToSide(bool showBack) async {
    await _flip.animateTo(
      showBack ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _isFlipped = showBack);
  }

  void _toggleFlip() => _animateToSide(!_isFlipped);

  void _onDragUpdate(DragUpdateDetails d) {
    _flip.stop();
    final delta = -d.delta.dx / 220;
    _flip.value = (_flip.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
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
    return Opacity(
      opacity: widget.frozen ? 0.55 : 1,
      child: AspectRatio(
        aspectRatio: _aspect,
        child: GestureDetector(
          onTap: _toggleFlip,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final t = _flip.value;
              final angle = t * math.pi;
              final showFront = angle <= math.pi / 2;

              return Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  _FlipSide(
                    visible: showFront,
                    angle: angle,
                    isFront: true,
                    child: _CardFace(
                      image: _frontAsset,
                      fallbackPath:
                          'packages/peyapay/assets/logo/cards/recto-carte-peya-pay.png',
                    ),
                  ),
                  _FlipSide(
                    visible: !showFront,
                    angle: angle,
                    isFront: false,
                    child: const _CardFace(
                      image: _backAsset,
                      fallbackPath:
                          'packages/peyapay/assets/logo/cards/verso.png',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FlipSide extends StatelessWidget {
  const _FlipSide({
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

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.image,
    required this.fallbackPath,
  });

  final AssetImage image;
  final String fallbackPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image(
        image: image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Image.asset(
          fallbackPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFF006D56),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.credit_card_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
