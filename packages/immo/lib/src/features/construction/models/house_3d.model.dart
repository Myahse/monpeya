import 'dart:math' as math;

import 'package:immo/src/features/construction/models/house_plan.model.dart';
import 'package:immo/src/features/construction/models/metre.model.dart';

typedef Point3 = ({double x, double y, double z});

/// A drawn [HousePlan] as solid walls, in metres: x along the plan's columns,
/// y along its rows, z up from the ground floor.
///
/// Every level repeats the plan, doors and windows included, as the métré counts
/// them (`MetreCalculator` subtracts the openings on each level). A sheet roof has
/// two slopes over the walls' rectangle, its ridge along the long side, as the
/// métré counts it.
class House3D {
  const House3D({
    required this.walls,
    required this.rooms,
    required this.levels,
    required this.levelHeight,
    this.roof = const [],
  });

  final List<WallBox> walls;

  /// One level's rooms, in metres; every level repeats them.
  final List<({String name, double x, double y, double w, double h})> rooms;

  final int levels;
  final double levelHeight;

  /// Both slopes, then both gables; empty for a terrace.
  final List<RoofFace> roof;

  /// Top of the last level.
  double get height => levels * levelHeight;

  factory House3D.of(
    HousePlan plan, {
    required int levels,
    required double wallHeight,
    MetreOpening doors = MetreInput.defaultDoors,
    MetreOpening windows = MetreInput.defaultWindows,
    int blockThickness = 15,
    bool flatRoof = true,
    double roofPitch = 25,
    double roofOverhang = 0.5,
  }) {
    final c = HousePlan.cell;
    final t = blockThickness / 100;
    final n = math.max(1, levels);
    final h = wallHeight > 0 ? wallHeight : 2.8;
    // Window tops line up with door tops, as on a site.
    final doorTop = math.min(doors.height, h);
    final windowBottom = math.max(0.0, doorTop - windows.height);

    // Openings by wall segment: where along the wall they cut, and between which heights.
    final cuts = <PlanEdge, _Cut>{};
    for (final o in plan.placedOpenings) {
      final mid = (o.edge.horizontal ? o.edge.x : o.edge.y) * c + c / 2;
      final width = o.kind == OpeningKind.door ? doors.width : windows.width;
      cuts[o.edge] = o.kind == OpeningKind.door
          ? _Cut(mid - width / 2, mid + width / 2, 0, doorTop)
          : _Cut(mid - width / 2, mid + width / 2, windowBottom, doorTop);
    }

    final walls = <WallBox>[];
    for (final run in _runs(plan.edges())) {
      final start = run.from * c - t / 2;
      final end = run.to * c + t / 2;
      final line = run.line * c;
      final runCuts = [for (final e in run.edges) ?cuts[e]];
      for (var level = 0; level < n; level++) {
        final base = level * h;
        // Slice the wall where an opening starts or ends; each slice is solid
        // over the level's height except where an opening covers it.
        final marks = {start, end, for (final k in runCuts) ...[k.from.clamp(start, end), k.to.clamp(start, end)]}
            .toList()
          ..sort();
        for (var i = 0; i + 1 < marks.length; i++) {
          final a = marks[i];
          final b = marks[i + 1];
          if (b - a < 1e-6) continue;
          final middle = (a + b) / 2;
          final holes = [
            for (final k in runCuts)
              if (k.from <= middle && middle <= k.to) (k.bottom, k.top),
          ]..sort((p, q) => p.$1.compareTo(q.$1));
          var z = 0.0;
          for (final (bottom, top) in [...holes, (h, h)]) {
            if (bottom - z > 1e-6) {
              walls.add(WallBox.along(
                horizontal: run.horizontal,
                from: a,
                to: b,
                line: line,
                thickness: t,
                bottom: base + z,
                top: base + bottom,
                exterior: run.exterior,
                level: level,
              ));
            }
            z = math.max(z, top);
          }
        }
      }
    }

    return House3D(
      walls: walls,
      rooms: [
        for (final r in plan.rooms) (name: r.name, x: r.x * c, y: r.y * c, w: r.w * c, h: r.h * c),
      ],
      levels: n,
      levelHeight: h,
      roof: flatRoof || walls.isEmpty ? const [] : _sheetRoof(walls, n * h, roofPitch, roofOverhang),
    );
  }

  /// Two slopes over the walls' outer rectangle, ridge along its long side, eaves
  /// [overhang] beyond the walls; a gable closes each short end.
  static List<RoofFace> _sheetRoof(List<WallBox> walls, double top, double pitch, double overhang) {
    final minX = walls.map((w) => w.x0).reduce(math.min);
    final maxX = walls.map((w) => w.x1).reduce(math.max);
    final minY = walls.map((w) => w.y0).reduce(math.min);
    final maxY = walls.map((w) => w.y1).reduce(math.max);
    final slope = math.tan(pitch.clamp(5, 60) * math.pi / 180);
    final d = overhang.clamp(0.0, 1.5);
    final alongX = maxX - minX >= maxY - minY;
    final half = (alongX ? maxY - minY : maxX - minX) / 2;
    final ridge = top + half * slope;
    final eave = top - d * slope;
    // Built as if the ridge ran along x, then swapped when it runs along y.
    final (a0, a1) = alongX ? (minX, maxX) : (minY, maxY);
    final (b0, b1) = alongX ? (minY, maxY) : (minX, maxX);
    final mid = (b0 + b1) / 2;
    Point3 p(double along, double across, double z) => alongX ? (x: along, y: across, z: z) : (x: across, y: along, z: z);
    return [
      RoofFace([p(a0 - d, b0 - d, eave), p(a1 + d, b0 - d, eave), p(a1 + d, mid, ridge), p(a0 - d, mid, ridge)]),
      RoofFace([p(a1 + d, b1 + d, eave), p(a0 - d, b1 + d, eave), p(a0 - d, mid, ridge), p(a1 + d, mid, ridge)]),
      RoofFace([p(a0, b1, top), p(a0, b0, top), p(a0, mid, ridge)], gable: true),
      RoofFace([p(a1, b0, top), p(a1, b1, top), p(a1, mid, ridge)], gable: true),
    ];
  }

  /// Wall edges merged into straight runs of one kind (exterior or interior).
  static List<_Run> _runs(Map<PlanEdge, int> edges) {
    final runs = <_Run>[];
    for (final horizontal in [true, false]) {
      final byLine = <int, List<PlanEdge>>{};
      for (final e in edges.keys.where((e) => e.horizontal == horizontal)) {
        byLine.putIfAbsent(horizontal ? e.y : e.x, () => []).add(e);
      }
      for (final MapEntry(key: line, value: list) in byLine.entries) {
        int pos(PlanEdge e) => horizontal ? e.x : e.y;
        list.sort((a, b) => pos(a).compareTo(pos(b)));
        _Run? current;
        for (final e in list) {
          final exterior = edges[e] == 1;
          final cur = current;
          if (cur != null && cur.to == pos(e) && cur.exterior == exterior) {
            current = cur.extended(e);
          } else {
            if (cur != null) runs.add(cur);
            current = _Run(horizontal, line, pos(e), pos(e) + 1, exterior, [e]);
          }
        }
        if (current != null) runs.add(current);
      }
    }
    return runs;
  }
}

/// One solid block of wall, axis-aligned, in metres.
class WallBox {
  const WallBox({
    required this.x0,
    required this.x1,
    required this.y0,
    required this.y1,
    required this.z0,
    required this.z1,
    required this.exterior,
    this.level = 0,
  });

  factory WallBox.along({
    required bool horizontal,
    required double from,
    required double to,
    required double line,
    required double thickness,
    required double bottom,
    required double top,
    required bool exterior,
    int level = 0,
  }) =>
      horizontal
          ? WallBox(
              x0: from, x1: to, y0: line - thickness / 2, y1: line + thickness / 2,
              z0: bottom, z1: top, exterior: exterior, level: level)
          : WallBox(
              x0: line - thickness / 2, x1: line + thickness / 2, y0: from, y1: to,
              z0: bottom, z1: top, exterior: exterior, level: level);

  final double x0;
  final double x1;
  final double y0;
  final double y1;
  final double z0;
  final double z1;
  final bool exterior;

  /// 0 for the ground floor.
  final int level;

  double get volume => (x1 - x0) * (y1 - y0) * (z1 - z0);
}

/// A flat polygon of the roof: a slope (sheets) or a gable (blocks).
class RoofFace {
  const RoofFace(this.corners, {this.gable = false});

  final List<Point3> corners;
  final bool gable;
}

class _Cut {
  const _Cut(this.from, this.to, this.bottom, this.top);

  final double from;
  final double to;
  final double bottom;
  final double top;
}

class _Run {
  const _Run(this.horizontal, this.line, this.from, this.to, this.exterior, this.edges);

  final bool horizontal;
  final int line;
  final int from;
  final int to;
  final bool exterior;
  final List<PlanEdge> edges;

  _Run extended(PlanEdge e) => _Run(horizontal, line, from, to + 1, exterior, [...edges, e]);
}
