import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/construction/models/house_3d.model.dart';
import 'package:immo/src/features/construction/models/house_plan.model.dart';
import 'package:immo/src/features/construction/models/metre.model.dart';
import 'package:immo/src/features/construction/widgets/construction_segment.style.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// The drawn house in 3D, read-only: every level, doors and windows cut out, and
/// the sheet roof. Drag to turn it or tilt it, pinch to zoom; above it, choose the
/// whole house, the house without its roof, or one floor with its rooms.
class PlanView3D extends StatefulWidget {
  const PlanView3D({
    super.key,
    required this.plan,
    required this.levels,
    required this.wallHeight,
    this.doors = MetreInput.defaultDoors,
    this.windows = MetreInput.defaultWindows,
    this.blockThickness = 15,
    this.flatRoof = true,
    this.roofPitch = 25,
    this.roofOverhang = 0.5,
  });

  /// A saved métré's drawing, with its elevation, opening sizes and roof.
  factory PlanView3D.ofInput(MetreInput input, {Key? key}) => PlanView3D(
        key: key,
        plan: input.plan ?? const HousePlan(),
        levels: input.levels,
        wallHeight: input.wallHeight,
        doors: input.doors,
        windows: input.windows,
        blockThickness: input.blockThickness,
        flatRoof: input.flatRoof,
        roofPitch: input.roofPitch,
        roofOverhang: input.roofOverhang,
      );

  final HousePlan plan;
  final int levels;
  final double wallHeight;
  final MetreOpening doors;
  final MetreOpening windows;
  final int blockThickness;
  final bool flatRoof;
  final double roofPitch;
  final double roofOverhang;

  @override
  State<PlanView3D> createState() => _PlanView3DState();
}

class _PlanView3DState extends State<PlanView3D> {
  /// Tilt range, in radians: from nearly level with the ground to nearly overhead.
  static const _lowest = 0.18;
  static const _highest = 1.4;
  static const _minZoom = 0.7;
  static const _maxZoom = 3.0;

  /// What the view shows: [_whole] house, [_withoutRoof], or one floor (0 = ground floor).
  static const _whole = -2;
  static const _withoutRoof = -1;

  double _turn = -0.6;
  double _tilt = 0.6;
  double _zoom = 1;
  int _view = _whole;
  late House3D _house = _build();

  final _fingers = <_Finger>[];
  double? _pinchFrom;
  double _zoomFrom = 1;

  House3D _build() => House3D.of(
        widget.plan,
        levels: widget.levels,
        wallHeight: widget.wallHeight,
        doors: widget.doors,
        windows: widget.windows,
        blockThickness: widget.blockThickness,
        flatRoof: widget.flatRoof,
        roofPitch: widget.roofPitch,
        roofOverhang: widget.roofOverhang,
      );

  @override
  void didUpdateWidget(PlanView3D old) {
    super.didUpdateWidget(old);
    if (old.plan != widget.plan ||
        old.levels != widget.levels ||
        old.wallHeight != widget.wallHeight ||
        old.blockThickness != widget.blockThickness ||
        old.doors != widget.doors ||
        old.windows != widget.windows ||
        old.flatRoof != widget.flatRoof ||
        old.roofPitch != widget.roofPitch ||
        old.roofOverhang != widget.roofOverhang) {
      _house = _build();
      if (_view >= _house.levels || (_view == _withoutRoof && _house.roof.isEmpty)) _view = _whole;
    }
  }

  /// One finger turns and tilts; a second one pinches to zoom.
  Drag? _onStart(Offset position) {
    if (_fingers.length >= 2) return null;
    late final _Finger finger;
    finger = _Finger(
      position,
      onUpdate: (d) => setState(() {
        finger.position += d.delta;
        if (_fingers.length == 1) {
          _turn += d.delta.dx * 0.012;
          _tilt = (_tilt + d.delta.dy * 0.008).clamp(_lowest, _highest);
        } else if (_pinchFrom case final from? when from > 0) {
          _zoom = (_zoomFrom * _spread() / from).clamp(_minZoom, _maxZoom);
        }
      }),
      onEnd: () {
        _fingers.remove(finger);
        _pinchFrom = null;
      },
    );
    _fingers.add(finger);
    if (_fingers.length == 2) {
      _pinchFrom = _spread();
      _zoomFrom = _zoom;
    }
    return finger;
  }

  double _spread() => (_fingers[0].position - _fingers[1].position).distance;

  List<(int, String)> get _views => [
        (_whole, 'Maison'),
        if (_house.roof.isNotEmpty) (_withoutRoof, 'Sans toit'),
        if (_house.levels > 1)
          for (var l = 0; l < _house.levels; l++) (l, l == 0 ? 'RDC' : 'R+$l'),
      ];

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final views = _views;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (views.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: [for (final (v, label) in views) ButtonSegment(value: v, label: Text(label))],
              selected: {_view},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _view = s.first),
              style: constructionSegmentStyle(b),
            ),
          ),
          const SizedBox(height: ImmoSpacing.sm),
        ],
        AspectRatio(
          aspectRatio: HousePlan.columns / HousePlan.rows,
          child: RawGestureDetector(
            gestures: {
              // Claims the fingers before the page's (or sheet's) scroll does, so turning never scrolls.
              ImmediateMultiDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
                ImmediateMultiDragGestureRecognizer.new,
                (r) => r.onStart = _onStart,
              ),
            },
            child: CustomPaint(
              painter: _HousePainter(
                house: _house,
                turn: _turn,
                tilt: _tilt,
                zoom: _zoom,
                floor: _view >= 0 ? _view : null,
                roof: _view == _whole,
                palette: b,
                labelStyle: DefaultTextStyle.of(context).style,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class _Finger extends Drag {
  _Finger(this.position, {required this.onUpdate, required this.onEnd});

  Offset position;
  final ValueChanged<DragUpdateDetails> onUpdate;
  final VoidCallback onEnd;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onEnd();

  @override
  void cancel() => onEnd();
}

/// Orthographic view of [house] turned by [turn] around the vertical and seen
/// from [tilt] above the ground. Levels are drawn bottom to top, each on its slab;
/// within a level, walls are cut into blocks of about 1 m and drawn far to near, so
/// a long wall never covers what stands in front of it. The roof comes last.
class _HousePainter extends CustomPainter {
  _HousePainter({
    required this.house,
    required this.turn,
    required this.tilt,
    required this.zoom,
    required this.floor,
    required this.roof,
    required this.palette,
    required this.labelStyle,
  });

  final House3D house;
  final double turn;
  final double tilt;
  final double zoom;

  /// The only level shown; null for all of them.
  final int? floor;
  final bool roof;
  final ImmoRentalPalette palette;
  final TextStyle labelStyle;

  static const _block = 1.0;

  /// Light from the plan's top-left, above: fixed to the house, so turning it shows its faces.
  static const _light = (x: -0.36, y: -0.63, z: 0.69);

  @override
  void paint(Canvas canvas, Size size) {
    final walls = house.walls;
    if (walls.isEmpty) return;
    final b = palette;

    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final w in walls) {
      minX = math.min(minX, w.x0);
      maxX = math.max(maxX, w.x1);
      minY = math.min(minY, w.y0);
      maxY = math.max(maxY, w.y1);
    }
    final top = house.roof.isEmpty
        ? house.height
        : house.roof.expand((f) => f.corners).map((p) => p.z).reduce(math.max);
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final cz = top / 2;
    // The circle the house sweeps when turned, and its farthest point at any tilt:
    // the scale never changes while the finger moves (only a pinch changes it).
    final overhang = house.roof.isEmpty ? 0.0 : 1.5;
    final radius = math.max(0.5, math.sqrt(math.pow(maxX - minX, 2) + math.pow(maxY - minY, 2)) / 2 + overhang);
    final reach = math.sqrt(radius * radius + cz * cz);
    final scale = zoom * 0.9 * math.min(size.width / (2 * radius), size.height / (2 * reach));

    final cosT = math.cos(turn), sinT = math.sin(turn);
    final cosP = math.cos(tilt), sinP = math.sin(tilt);

    // Plan rows run down the page, so y is flipped to run away from the viewer.
    (double, double) turned(double x, double y) {
      final dx = x - cx, dy = cy - y;
      return (dx * cosT - dy * sinT, dx * sinT + dy * cosT);
    }

    Offset screen(double x, double y, double z) {
      final (u, v) = turned(x, y);
      return Offset(size.width / 2 + u * scale, size.height / 2 - (v * sinP + (z - cz) * cosP) * scale);
    }

    double depth(double x, double y, double z) {
      final (_, v) = turned(x, y);
      return v * cosP - (z - cz) * sinP;
    }

    /// Whether a face with this outward normal (plan axes, unit length) faces the viewer, and how lit it is.
    (bool, double) facing(double nx, double ny, double nz) {
      final v = nx * sinT - ny * cosT;
      final visible = -v * cosP + nz * sinP > 1e-6;
      final lit = math.max(0.0, nx * _light.x + ny * _light.y + nz * _light.z);
      return (visible, lit);
    }

    // Faces go from shadow to light in either scheme: on a dark card the lit ones are the bright ones.
    final shadow = b.isDark ? b.card : b.text;
    final lit = b.isDark ? b.text : b.card;
    Color shade(double light) => Color.lerp(shadow, lit, light.clamp(0.0, 0.85))!;
    final fill = Paint()..isAntiAlias = true;
    // Same colour as the fill: closes the hairline seams between neighbouring blocks.
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    void face(List<Offset> corners, Color color) {
      final path = Path()..addPolygon(corners, true);
      canvas.drawPath(path, fill..color = color);
      canvas.drawPath(path, seam..color = color);
    }

    final shown = floor == null ? [for (var l = 0; l < house.levels; l++) l] : [floor!];
    for (final level in shown) {
      final z = level * house.levelHeight;

      // The level's floor: the ground slab, or the concrete slab between floors.
      final slab = level == 0
          ? b.primary.withValues(alpha: 0.10)
          : Color.alphaBlend(b.primary.withValues(alpha: 0.10), shade(0.75));
      for (final r in house.rooms) {
        face([
          screen(r.x, r.y, z),
          screen(r.x + r.w, r.y, z),
          screen(r.x + r.w, r.y + r.h, z),
          screen(r.x, r.y + r.h, z),
        ], slab);
      }

      final blocks = <(double, WallBox)>[];
      for (final w in walls.where((w) => w.level == level)) {
        final horizontal = w.x1 - w.x0 >= w.y1 - w.y0;
        final length = horizontal ? w.x1 - w.x0 : w.y1 - w.y0;
        final pieces = math.max(1, (length / _block).ceil());
        for (var i = 0; i < pieces; i++) {
          final from = i / pieces, to = (i + 1) / pieces;
          final piece = horizontal
              ? WallBox(x0: w.x0 + (w.x1 - w.x0) * from, x1: w.x0 + (w.x1 - w.x0) * to, y0: w.y0, y1: w.y1, z0: w.z0, z1: w.z1, exterior: w.exterior)
              : WallBox(x0: w.x0, x1: w.x1, y0: w.y0 + (w.y1 - w.y0) * from, y1: w.y0 + (w.y1 - w.y0) * to, z0: w.z0, z1: w.z1, exterior: w.exterior);
          blocks.add((
            depth((piece.x0 + piece.x1) / 2, (piece.y0 + piece.y1) / 2, (piece.z0 + piece.z1) / 2),
            piece,
          ));
        }
      }
      blocks.sort((p, q) => q.$1.compareTo(p.$1));

      for (final (_, w) in blocks) {
        final sides = [
          (1.0, 0.0, [(w.x1, w.y0), (w.x1, w.y1)]),
          (-1.0, 0.0, [(w.x0, w.y1), (w.x0, w.y0)]),
          (0.0, 1.0, [(w.x1, w.y1), (w.x0, w.y1)]),
          (0.0, -1.0, [(w.x0, w.y0), (w.x1, w.y0)]),
        ];
        for (final (nx, ny, ends) in sides) {
          final (visible, brightness) = facing(nx, ny, 0);
          if (!visible) continue;
          final (p, q) = (ends[0], ends[1]);
          face([
            screen(p.$1, p.$2, w.z0),
            screen(q.$1, q.$2, w.z0),
            screen(q.$1, q.$2, w.z1),
            screen(p.$1, p.$2, w.z1),
          ], shade((w.exterior ? 0.3 : 0.45) + 0.45 * brightness));
        }
        face([
          screen(w.x0, w.y0, w.z1),
          screen(w.x1, w.y0, w.z1),
          screen(w.x1, w.y1, w.z1),
          screen(w.x0, w.y1, w.z1),
        ], w.exterior ? b.text : b.text.withValues(alpha: 0.7));
      }

      // Room names on the floor you look into (one floor alone, or the top one without its roof),
      // over its walls and haloed in the card colour so a wall never hides them.
      if (floor == level || (floor == null && !roof && level == house.levels - 1)) {
        final style = labelStyle.copyWith(fontSize: 10.5, height: 1.25, fontWeight: FontWeight.w700);
        for (final r in house.rooms) {
          final at = screen(r.x + r.w / 2, r.y + r.h / 2, z);
          TextPainter label(TextStyle s) => TextPainter(
                text: TextSpan(text: r.name, style: s),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                maxLines: 1,
              )..layout();
          final halo = label(style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeJoin = StrokeJoin.round
              ..color = b.card,
          ));
          final text = label(style.copyWith(color: b.text));
          final corner = at - Offset(text.width / 2, text.height / 2);
          halo.paint(canvas, corner);
          text.paint(canvas, corner);
        }
      }
    }

    if (roof && floor == null && house.roof.isNotEmpty) {
      // Normals from the polygon, turned to point away from the house's centre.
      final roofFaces = <(double, RoofFace, double, double, double)>[];
      for (final f in house.roof) {
        final [p0, p1, p2, ...] = f.corners;
        var nx = (p1.y - p0.y) * (p2.z - p0.z) - (p1.z - p0.z) * (p2.y - p0.y);
        var ny = (p1.z - p0.z) * (p2.x - p0.x) - (p1.x - p0.x) * (p2.z - p0.z);
        var nz = (p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x);
        final n = math.sqrt(nx * nx + ny * ny + nz * nz);
        if (n < 1e-9) continue;
        nx /= n;
        ny /= n;
        nz /= n;
        final mx = f.corners.map((p) => p.x).reduce((a, c) => a + c) / f.corners.length;
        final my = f.corners.map((p) => p.y).reduce((a, c) => a + c) / f.corners.length;
        final mz = f.corners.map((p) => p.z).reduce((a, c) => a + c) / f.corners.length;
        if (nx * (mx - cx) + ny * (my - cy) + nz * (mz - house.height / 2) < 0) {
          nx = -nx;
          ny = -ny;
          nz = -nz;
        }
        roofFaces.add((depth(mx, my, mz), f, nx, ny, nz));
      }
      roofFaces.sort((p, q) => q.$1.compareTo(p.$1));
      for (final (_, f, nx, ny, nz) in roofFaces) {
        final (visible, brightness) = facing(nx, ny, nz);
        if (!visible) continue;
        final color = f.gable
            ? shade(0.3 + 0.45 * brightness)
            : Color.lerp(shade(0.35 + 0.5 * brightness), b.primary, 0.22)!;
        face([for (final p in f.corners) screen(p.x, p.y, p.z)], color);
      }
    }
  }

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.house != house ||
      old.turn != turn ||
      old.tilt != tilt ||
      old.zoom != zoom ||
      old.floor != floor ||
      old.roof != roof ||
      old.palette != palette;
}
