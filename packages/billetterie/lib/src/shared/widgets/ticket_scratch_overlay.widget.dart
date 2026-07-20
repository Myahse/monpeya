import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// How the QR on the ticket back is gated.
enum TicketQrRevealMode {
  /// Catalog / not purchased — foil covers QR, scratching disabled.
  locked,

  /// Owned / just purchased — user scratches to reveal.
  scratchable,

  /// Already revealed — QR fully visible.
  revealed,
}

/// Silver foil over the QR. Scratchable when [mode] is [TicketQrRevealMode.scratchable].
class TicketScratchOverlay extends StatefulWidget {
  const TicketScratchOverlay({
    super.key,
    required this.mode,
    this.onFullyRevealed,
    this.onLockedTap,
    this.revealThreshold = 0.55,
  });

  final TicketQrRevealMode mode;
  final VoidCallback? onFullyRevealed;

  /// When locked (non-scratchable), tap can flip back.
  final VoidCallback? onLockedTap;

  /// Fraction of the foil that must be cleared before auto-reveal.
  final double revealThreshold;

  @override
  State<TicketScratchOverlay> createState() => _TicketScratchOverlayState();
}

class _TicketScratchOverlayState extends State<TicketScratchOverlay> {
  final _points = <Offset?>[];
  bool _done = false;
  Size? _size;

  @override
  void didUpdateWidget(covariant TicketScratchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode &&
        widget.mode == TicketQrRevealMode.revealed) {
      _done = true;
    }
  }

  void _addPoint(Offset p) {
    if (_done || widget.mode != TicketQrRevealMode.scratchable) return;
    setState(() => _points.add(p));
  }

  void _endStroke() {
    if (_done || widget.mode != TicketQrRevealMode.scratchable) return;
    setState(() => _points.add(null));
    _checkReveal();
  }

  void _checkReveal() {
    final size = _size;
    if (size == null || size.isEmpty) return;
    final cleared = _estimateClearedFraction(size);
    if (cleared >= widget.revealThreshold) {
      setState(() => _done = true);
      widget.onFullyRevealed?.call();
    }
  }

  /// Rough estimate: sample a grid and count cells near scratch strokes.
  double _estimateClearedFraction(Size size) {
    const cols = 12;
    const rows = 12;
    const radius = 22.0;
    final hit = List.generate(rows, (_) => List.filled(cols, false));
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (final p in _points) {
      if (p == null) continue;
      final minC = ((p.dx - radius) / cellW).floor().clamp(0, cols - 1);
      final maxC = ((p.dx + radius) / cellW).ceil().clamp(0, cols - 1);
      final minR = ((p.dy - radius) / cellH).floor().clamp(0, rows - 1);
      final maxR = ((p.dy + radius) / cellH).ceil().clamp(0, rows - 1);
      for (var r = minR; r <= maxR; r++) {
        for (var c = minC; c <= maxC; c++) {
          final cx = (c + 0.5) * cellW;
          final cy = (r + 0.5) * cellH;
          if ((Offset(cx, cy) - p).distance <= radius) {
            hit[r][c] = true;
          }
        }
      }
    }

    var n = 0;
    for (final row in hit) {
      for (final v in row) {
        if (v) n++;
      }
    }
    return n / (cols * rows);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == TicketQrRevealMode.revealed || _done) {
      return const SizedBox.shrink();
    }

    final locked = widget.mode == TicketQrRevealMode.locked;

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: locked ? widget.onLockedTap : null,
              onPanStart: locked
                  ? null
                  : (d) => _addPoint(d.localPosition),
              onPanUpdate: locked
                  ? null
                  : (d) => _addPoint(d.localPosition),
              onPanEnd: locked ? null : (_) => _endStroke(),
              child: CustomPaint(
                painter: _ScratchFoilPainter(
                  points: _points,
                  locked: locked,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            if (!locked && _points.isEmpty)
              const IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xF2FFFFFF),
                          size: 28,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Grattez pour\nrévéler le QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScratchFoilPainter extends CustomPainter {
  _ScratchFoilPainter({required this.points, required this.locked});

  final List<Offset?> points;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.saveLayer(rect, Paint());

    final foil = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [Color(0xFFC0C0C0), Color(0xFFE8E8E8), Color(0xFF9CA3AF)],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(rect, foil);

    // Subtle glitter lines.
    final glitter = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.2;
    for (var i = -size.height; i < size.width + size.height; i += 14) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i + size.height, size.height),
        glitter,
      );
    }

    if (!locked && points.isNotEmpty) {
      final clear = Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      Offset? last;
      for (final p in points) {
        if (p == null) {
          last = null;
          continue;
        }
        if (last == null) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        last = p;
      }
      canvas.drawPath(path, clear);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchFoilPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.points.length != points.length ||
      oldDelegate.locked != locked;
}
