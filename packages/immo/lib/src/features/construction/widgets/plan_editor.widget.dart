import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/features/construction/models/house_plan.model.dart';

enum PlanTool { room, door, window }

/// The house drawn on a 50 cm grid. With [PlanTool.room], drag to draw a room
/// and tap a room to edit it; with door / window, tap a wall to add or remove one.
class PlanEditor extends StatefulWidget {
  const PlanEditor({
    super.key,
    required this.plan,
    required this.tool,
    required this.onChanged,
    required this.onRoomDrawn,
    required this.onRoomTapped,
  });

  final HousePlan plan;
  final PlanTool tool;
  final ValueChanged<HousePlan> onChanged;
  final ValueChanged<PlanRoom> onRoomDrawn;
  final ValueChanged<int> onRoomTapped;

  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  final _canvas = GlobalKey();
  Offset? _start;
  Offset? _current;
  bool _dragging = false;

  /// Point on the canvas, in grid cells.
  Offset _cells(Offset global) {
    final box = _canvas.currentContext!.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(global);
    final cell = box.size.width / HousePlan.columns;
    return Offset(local.dx / cell, local.dy / cell);
  }

  Drag? _onStart(Offset global) {
    if (_dragging) return null;
    _dragging = true;
    setState(() => _start = _current = _cells(global));
    return _PlanDrag(
      onUpdate: (d) => setState(() => _current = _cells(d.globalPosition)),
      onEnd: _finish,
    );
  }

  void _finish() {
    final start = _start;
    final end = _current;
    _dragging = false;
    setState(() => _start = _current = null);
    if (start == null || end == null) return;
    final moved = (end - start).distance;
    if (moved < 1) {
      _tap(start);
    } else if (widget.tool == PlanTool.room) {
      final r = _rect(start, end);
      if (r == null) return;
      if (widget.plan.overlaps(r)) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Une pièce ne peut pas en chevaucher une autre.')),
        );
        return;
      }
      widget.onRoomDrawn(r);
    }
  }

  void _tap(Offset at) {
    final plan = widget.plan;
    if (widget.tool == PlanTool.room) {
      final i = plan.rooms.indexWhere((r) => r.contains(at.dx, at.dy));
      if (i >= 0) widget.onRoomTapped(i);
      return;
    }
    final edge = plan.nearestEdge(at.dx, at.dy);
    if (edge == null) return;
    final kind = widget.tool == PlanTool.door ? OpeningKind.door : OpeningKind.window;
    final openings = [...plan.placedOpenings];
    final existing = openings.indexWhere((o) => o.edge == edge);
    if (existing >= 0) {
      openings.removeAt(existing);
    } else {
      openings.add(PlanOpening(kind: kind, edge: edge));
    }
    widget.onChanged(plan.copyWith(openings: openings));
  }

  /// Snapped rectangle between two points; null when under 1 m in a direction.
  static PlanRoom? _rect(Offset a, Offset b) {
    int clampX(double v) => v.round().clamp(0, HousePlan.columns);
    int clampY(double v) => v.round().clamp(0, HousePlan.rows);
    final x1 = clampX(math.min(a.dx, b.dx));
    final x2 = clampX(math.max(a.dx, b.dx));
    final y1 = clampY(math.min(a.dy, b.dy));
    final y2 = clampY(math.max(a.dy, b.dy));
    if (x2 - x1 < 2 || y2 - y1 < 2) return null;
    return PlanRoom(name: '', x: x1, y: y1, w: x2 - x1, h: y2 - y1);
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final preview = _start == null || _current == null || widget.tool != PlanTool.room
        ? null
        : _rect(_start!, _current!);
    return AspectRatio(
      aspectRatio: HousePlan.columns / HousePlan.rows,
      child: RawGestureDetector(
        gestures: {
          // A still tap never ends a drag, so taps get their own recognizer.
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            TapGestureRecognizer.new,
            (r) => r.onTapUp = (d) => _tap(_cells(d.globalPosition)),
          ),
          // Claims the finger before the page's scroll does, so drawing never scrolls.
          ImmediateMultiDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
            ImmediateMultiDragGestureRecognizer.new,
            (r) => r.onStart = _onStart,
          ),
        },
        child: CustomPaint(
          key: _canvas,
          painter: _PlanPainter(
            plan: widget.plan,
            preview: preview,
            palette: b,
            labelStyle: DefaultTextStyle.of(context).style,
          ),
        ),
      ),
    );
  }
}

class _PlanDrag extends Drag {
  _PlanDrag({required this.onUpdate, required this.onEnd});

  final ValueChanged<DragUpdateDetails> onUpdate;
  final VoidCallback onEnd;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onEnd();

  @override
  void cancel() => onEnd();
}

class _PlanPainter extends CustomPainter {
  _PlanPainter({
    required this.plan,
    required this.preview,
    required this.palette,
    required this.labelStyle,
  });

  final HousePlan plan;
  final PlanRoom? preview;
  final ImmoRentalPalette palette;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / HousePlan.columns;
    final b = palette;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = b.card,
    );

    // 1 m grid, stronger every 5 m
    for (var i = 0; i <= HousePlan.columns; i += 2) {
      final strong = i % 10 == 0;
      canvas.drawLine(Offset(i * c, 0), Offset(i * c, size.height),
          Paint()..color = b.border.withValues(alpha: strong ? 0.9 : 0.45)..strokeWidth = strong ? 1 : 0.6);
    }
    for (var j = 0; j <= HousePlan.rows; j += 2) {
      final strong = j % 10 == 0;
      canvas.drawLine(Offset(0, j * c), Offset(size.width, j * c),
          Paint()..color = b.border.withValues(alpha: strong ? 0.9 : 0.45)..strokeWidth = strong ? 1 : 0.6);
    }

    for (final r in plan.rooms) {
      canvas.drawRect(_rect(r, c), Paint()..color = b.primary.withValues(alpha: 0.10));
    }

    final exterior = Paint()
      ..color = b.text
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.square;
    final interior = Paint()
      ..color = b.text.withValues(alpha: 0.7)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;
    plan.edges().forEach((e, n) {
      final (p1, p2) = _ends(e, c);
      canvas.drawLine(p1, p2, n == 1 ? exterior : interior);
    });

    for (final o in plan.placedOpenings) {
      final (p1, p2) = _ends(o.edge, c);
      canvas.drawLine(p1, p2, Paint()..color = b.card..strokeWidth = 4.5);
      if (o.kind == OpeningKind.door) {
        // Leaf + swing, like an architect's plan
        final leafEnd = o.edge.horizontal ? Offset(p1.dx, p1.dy + c) : Offset(p1.dx + c, p1.dy);
        final door = Paint()
          ..color = b.primary
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        canvas.drawLine(p1, leafEnd, door);
        final arcRect = Rect.fromCircle(center: p1, radius: c);
        canvas.drawArc(arcRect, o.edge.horizontal ? 0 : math.pi / 2, o.edge.horizontal ? math.pi / 2 : -math.pi / 2,
            false, door);
      } else {
        final glass = Paint()
          ..color = b.primary
          ..strokeWidth = 1.4;
        final shift = o.edge.horizontal ? const Offset(0, 2) : const Offset(2, 0);
        canvas.drawLine(p1 - shift, p2 - shift, glass);
        canvas.drawLine(p1 + shift, p2 + shift, glass);
      }
    }

    for (final r in plan.rooms) {
      final rect = _rect(r, c);
      final text = '${r.name}\n${formatNumber(r.w * HousePlan.cell)} × ${formatNumber(r.h * HousePlan.cell)} m';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: labelStyle.copyWith(fontSize: 10.5, height: 1.25, color: b.text, fontWeight: FontWeight.w700),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: math.max(0, rect.width - 4));
      if (tp.height < rect.height - 2) {
        tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
      }
    }

    final p = preview;
    if (p != null) {
      final overlap = plan.overlaps(p);
      final color = overlap ? b.danger : b.primary;
      canvas.drawRect(_rect(p, c), Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawRect(
        _rect(p, c),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  static Rect _rect(PlanRoom r, double c) => Rect.fromLTWH(r.x * c, r.y * c, r.w * c, r.h * c);

  static (Offset, Offset) _ends(PlanEdge e, double c) => e.horizontal
      ? (Offset(e.x * c, e.y * c), Offset((e.x + 1) * c, e.y * c))
      : (Offset(e.x * c, e.y * c), Offset(e.x * c, (e.y + 1) * c));

  @override
  bool shouldRepaint(_PlanPainter old) =>
      old.plan != plan || old.preview?.toJson().toString() != preview?.toJson().toString() || old.palette != palette;
}
