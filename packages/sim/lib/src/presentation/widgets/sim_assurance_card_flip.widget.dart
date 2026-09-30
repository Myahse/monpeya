import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sim/src/data/models/sim_assurance_card.model.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';

/// Carte assurance 3D (même principe que la carte bancaire Peya Pay).
class SimAssuranceCardFlip extends StatefulWidget {
  const SimAssuranceCardFlip({
    super.key,
    required this.record,
    this.compact = false,
    this.frozen = false,
  });

  final SimAssuranceCardRecord record;
  final bool compact;
  final bool frozen;

  @override
  State<SimAssuranceCardFlip> createState() => _SimAssuranceCardFlipState();
}

class _SimAssuranceCardFlipState extends State<SimAssuranceCardFlip> with SingleTickerProviderStateMixin {
  static const _cardHeight = 200.0;
  static const _compactCardHeight = 168.0;

  late final AnimationController _flip;
  bool _isFlipped = false;

  double get _height => widget.compact ? _compactCardHeight : _cardHeight;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
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
    final record = widget.record;
    final opacity = widget.frozen ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: GestureDetector(
          onTap: _toggleFlip,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
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
                    child: _SimCardFront(record: record, compact: widget.compact),
                  ),
                  _CardSide(
                    visible: !showFront,
                    angle: angle,
                    isFront: false,
                    child: _SimCardBack(
                      record: record,
                      compact: widget.compact,
                      pngBytes: record.cartePngBytes,
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

class _SimCardShell extends StatelessWidget {
  const _SimCardShell({
    required this.compact,
    required this.gradient,
    required this.child,
    this.borderColor = const Color(0x33000000),
  });

  final bool compact;
  final List<Color> gradient;
  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: compact ? 12 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SimCardFront extends StatelessWidget {
  const _SimCardFront({required this.record, required this.compact});

  final SimAssuranceCardRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final police = record.numeroPolice.isEmpty ? '— — —' : record.numeroPolice;
    final holder = record.holderName.isEmpty ? 'ASSURÉ' : record.holderName.toUpperCase();
    final expiry = record.shortEndDate;

    return _SimCardShell(
      compact: compact,
      gradient: const [SimBrand.gradientTop, SimBrand.primaryDark],
      borderColor: Colors.white.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.95), size: compact ? 18 : 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SIM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 11 : 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (record.isActive ? Colors.white : Colors.black26).withValues(alpha: record.isActive ? 0.22 : 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      record.statusLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          Text(
            police,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          Text(
            record.productLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _FooterBlock(label: 'ASSURÉ', value: holder, compact: compact),
              _FooterBlock(label: 'FIN', value: expiry, compact: compact),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              'Glisser pour la carte de prise en charge',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimCardBack extends StatelessWidget {
  const _SimCardBack({
    required this.record,
    required this.compact,
    required this.pngBytes,
  });

  final SimAssuranceCardRecord record;
  final bool compact;
  final Uint8List? pngBytes;

  @override
  Widget build(BuildContext context) {
    return _SimCardShell(
      compact: compact,
      gradient: const [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      borderColor: const Color(0xFFDADADA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Carte de prise en charge',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: SimBrand.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            record.validityLabel,
            style: TextStyle(fontSize: compact ? 10 : 11, color: SimBrand.textDark.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: pngBytes != null
                  ? Image.memory(pngBytes!, fit: BoxFit.contain)
                  : Container(
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: Text(
                        'Carte non téléchargée',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBlock extends StatelessWidget {
  const _FooterBlock({required this.label, required this.value, required this.compact});

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
