import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:peyapay/src/core/constants/peya_pay.assets.dart';


class PeyapayDebitCardPreview extends StatefulWidget {
  const PeyapayDebitCardPreview({
    super.key,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    required this.showDetails,
    this.compact = false,
  });

  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final bool showDetails;
  final bool compact;

  @override
  State<PeyapayDebitCardPreview> createState() => _PeyapayDebitCardPreviewState();
}

class _PeyapayDebitCardPreviewState extends State<PeyapayDebitCardPreview> with SingleTickerProviderStateMixin {
  static const _cardHeight = 200.0;
  static const _compactCardHeight = 160.0;

  double get _cardHeightValue => widget.compact ? _compactCardHeight : _cardHeight;

  late final AnimationController _flip;
  bool _isFlipped = false;

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

  String get _cardType {
    final d = widget.cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('4')) return 'VISA';
    if (d.startsWith('5')) return 'MASTERCARD';
    return 'CARD';
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
    final cardHeight = _cardHeightValue;
    final padding = widget.compact
        ? const EdgeInsets.fromLTRB(4, 4, 4, 10)
        : const EdgeInsets.fromLTRB(4, 8, 4, 20);

    return Padding(
      padding: padding,
      child: SizedBox(
        height: cardHeight,
        width: double.infinity,
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

              return SizedBox(
                height: cardHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    _CardSide(
                      visible: showFront,
                      angle: angle,
                      isFront: true,
                      child: _CardFront(
                      compact: widget.compact,
                      cardType: _cardType,
                      cardNumber: widget.cardNumber,
                      cardHolder: widget.cardHolder,
                      expiryDate: widget.expiryDate,
                      showDetails: widget.showDetails,
                      flipHint: 'Swipe to see CVV',
                    ),
                  ),
                  _CardSide(
                    visible: !showFront,
                    angle: angle,
                    isFront: false,
                    child: _CardBack(
                      compact: widget.compact,
                      cardType: _cardType,
                      cardHolder: widget.cardHolder,
                      cvv: widget.cvv,
                      showDetails: widget.showDetails,
                      flipHint: 'Swipe to see front',
                    ),
                  ),
                  ],
                ),
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
    // Front: 0° → 180°. Back: 180° → 360° (RN backfaceVisibility pattern).
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

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.compact,
    required this.cardType,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.showDetails,
    required this.flipHint,
  });

  final bool compact;
  final String cardType;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final bool showDetails;
  final String flipHint;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (cardType) {
      'VISA' => const [Color(0xFFFFFFFF), Color(0xFFF0F8FF)],
      'MASTERCARD' => const [Color(0xFFFFFFFF), Color(0xFFFFF0F0)],
      _ => const [Color(0xFFFFFFFF), Color(0xFFF8F8F8)],
    };

    final displayNumber = showDetails
        ? (cardNumber.isEmpty ? 'XXXX XXXX XXXX XXXX' : cardNumber)
        : '•••• •••• •••• ••••';
    final displayHolder = showDetails
        ? (cardHolder.isEmpty ? 'YOUR NAME' : cardHolder.toUpperCase())
        : '••••••••';
    final displayExpiry = showDetails ? (expiryDate.isEmpty ? 'MM/YY' : expiryDate) : '••/••';

    return _CardShell(
      compact: compact,
      gradient: gradient,
      borderColor: const Color(0xFFDADADA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: compact ? 32 : 38,
                height: compact ? 22 : 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEED285),
                  borderRadius: BorderRadius.circular(compact ? 4 : 6),
                  border: Border.all(color: const Color(0xFFD9B452)),
                ),
              ),
              _BrandBadge(cardType: cardType, compact: compact),
            ],
          ),
          SizedBox(height: compact ? 10 : 20),
          Text(
            displayNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 14 : 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF333333),
              letterSpacing: compact ? 1 : 2,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _FooterBlock(label: 'CARD HOLDER', value: displayHolder, compact: compact),
              _FooterBlock(label: 'EXPIRES', value: displayExpiry, compact: compact),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            _FlipHint(text: flipHint),
          ],
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.compact,
    required this.cardType,
    required this.cardHolder,
    required this.cvv,
    required this.showDetails,
    required this.flipHint,
  });

  final bool compact;
  final String cardType;
  final String cardHolder;
  final String cvv;
  final bool showDetails;
  final String flipHint;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (cardType) {
      'VISA' => const [Color(0xFFF0F8FF), Color(0xFFFFFFFF)],
      'MASTERCARD' => const [Color(0xFFFFF0F0), Color(0xFFFFFFFF)],
      _ => const [Color(0xFFF8F8F8), Color(0xFFFFFFFF)],
    };

    final displayHolder = showDetails
        ? (cardHolder.isEmpty ? 'YOUR NAME' : cardHolder)
        : '••••••••';
    final displayCvv = showDetails ? (cvv.isEmpty ? 'CVV' : cvv) : '•••';

    return _CardShell(
      compact: compact,
      gradient: gradient,
      borderColor: const Color(0xFFDADADA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: compact ? 4 : 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Transform.translate(
                offset: const Offset(-4, 0),
                child: SizedBox(
                  width: constraints.maxWidth + 8,
                  height: compact ? 28 : 35,
                  child: const ColoredBox(color: Color(0xFF333333)),
                ),
              );
            },
          ),
          SizedBox(height: compact ? 8 : 12),
          Container(
            height: compact ? 32 : 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      border: const Border(right: BorderSide(color: Color(0xFFDDDDDD))),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayHolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: compact ? 56 : 70,
                  margin: const EdgeInsets.only(right: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: Text(
                    displayCvv,
                    style: TextStyle(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!compact) ...[
            const Text(
              'This card is property of PeyaPay. Authorized use only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 6),
            _FlipHint(text: flipHint),
          ],
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.compact,
    required this.gradient,
    required this.borderColor,
    required this.child,
  });

  final bool compact;
  final List<Color> gradient;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: child,
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.cardType, this.compact = false});

  final String cardType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (cardType == 'VISA') {
      return Image.asset(
      'assets/logo/cards/visa.png',
      package: PeyaPayAssets.package,
        height: compact ? 26 : 35,
        width: compact ? 48 : 65,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Text('VISA', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1F71))),
      );
    }
    if (cardType == 'MASTERCARD') {
      return Image.asset(
      'assets/logo/cards/Mastercard.png',
      package: PeyaPayAssets.package,
        height: compact ? 26 : 35,
        width: compact ? 48 : 65,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Text('MC', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEB001B))),
      );
    }
    return Text(
      cardType,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF333333)),
    );
  }
}

class _FooterBlock extends StatelessWidget {
  const _FooterBlock({required this.label, required this.value, this.compact = false});

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 8 : 9,
            color: const Color(0xFF999999),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}

class _FlipHint extends StatelessWidget {
  const _FlipHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xB3FFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, size: 14, color: Color(0xFF666666)),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
          ],
        ),
      ),
    );
  }
}
