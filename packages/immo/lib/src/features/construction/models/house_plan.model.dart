import 'package:immo/src/features/construction/models/metre.model.dart';

/// A house drawn as rectangular rooms on a 50 cm grid, with doors and windows
/// placed on wall edges. Everything is in grid cells; [cell] converts to metres.
class HousePlan {
  const HousePlan({this.rooms = const [], this.openings = const []});

  static const cell = 0.5;

  /// Drawing area, in cells (24 × 18 m): room for a large house, cells big enough for a finger.
  static const columns = 48;
  static const rows = 36;

  final List<PlanRoom> rooms;
  final List<PlanOpening> openings;

  bool get isEmpty => rooms.isEmpty;

  /// Wall edge lengths in metres: an edge of one room is exterior, an edge
  /// two rooms share is interior.
  ({double exterior, double interior}) walls() {
    final counts = edges();
    var exterior = 0;
    var interior = 0;
    for (final n in counts.values) {
      n == 1 ? exterior++ : interior++;
    }
    return (exterior: exterior * cell, interior: interior * cell);
  }

  double get floorArea => rooms.fold<int>(0, (s, r) => s + r.w * r.h) * cell * cell;

  /// Bounding rectangle in metres.
  ({double length, double width}) get bounds {
    if (rooms.isEmpty) return (length: 0, width: 0);
    final minX = rooms.map((r) => r.x).reduce((a, b) => a < b ? a : b);
    final minY = rooms.map((r) => r.y).reduce((a, b) => a < b ? a : b);
    final maxX = rooms.map((r) => r.x + r.w).reduce((a, b) => a > b ? a : b);
    final maxY = rooms.map((r) => r.y + r.h).reduce((a, b) => a > b ? a : b);
    return (length: (maxX - minX) * cell, width: (maxY - minY) * cell);
  }

  int count(OpeningKind kind) => openings.where((o) => o.kind == kind).length;

  /// Whether [r] would overlap another room ([except] = index being edited).
  bool overlaps(PlanRoom r, {int? except}) {
    for (var i = 0; i < rooms.length; i++) {
      if (i == except) continue;
      final o = rooms[i];
      if (r.x < o.x + o.w && o.x < r.x + r.w && r.y < o.y + o.h && o.y < r.y + r.h) return true;
    }
    return false;
  }

  /// The wall edge (unit segment) nearest to a point given in cells, if within [tolerance].
  PlanEdge? nearestEdge(double cx, double cy, {double tolerance = 0.8}) {
    PlanEdge? best;
    var bestDistance = tolerance;
    for (final e in edges().keys) {
      final mx = e.horizontal ? e.x + 0.5 : e.x.toDouble();
      final my = e.horizontal ? e.y.toDouble() : e.y + 0.5;
      final d = (cx - mx).abs() + (cy - my).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = e;
      }
    }
    return best;
  }

  /// Openings that are still on a wall (rooms may have moved or been deleted).
  List<PlanOpening> get placedOpenings {
    final walls = edges().keys.toSet();
    return openings.where((o) => walls.contains(o.edge)).toList();
  }

  HousePlan copyWith({List<PlanRoom>? rooms, List<PlanOpening>? openings}) =>
      HousePlan(rooms: rooms ?? this.rooms, openings: openings ?? this.openings);

  /// The métré this drawing describes; levels, height and options come from [base].
  MetreInput toInput(MetreInput base) {
    final w = walls();
    final b = bounds;
    return MetreInput(
      length: b.length,
      width: b.width,
      levels: base.levels,
      wallHeight: base.wallHeight,
      rooms: [for (final r in rooms) MetreRoom(name: r.name, length: r.w * cell, width: r.h * cell)],
      interiorWalls: w.interior,
      exteriorWalls: w.exterior,
      footprintArea: floorArea,
      doors: MetreOpening(count: count(OpeningKind.door), width: base.doors.width, height: base.doors.height),
      windows: MetreOpening(count: count(OpeningKind.window), width: base.windows.width, height: base.windows.height),
      blockThickness: base.blockThickness,
      flatRoof: base.flatRoof,
      roofPitch: base.roofPitch,
      roofOverhang: base.roofOverhang,
      steelFrame: base.steelFrame,
      waste: base.waste,
      plan: this,
    );
  }

  /// Each 50 cm wall segment with how many rooms it bounds (1 = exterior, 2 = interior).
  Map<PlanEdge, int> edges() {
    final counts = <PlanEdge, int>{};
    void add(PlanEdge e) => counts[e] = (counts[e] ?? 0) + 1;
    for (final r in rooms) {
      for (var x = r.x; x < r.x + r.w; x++) {
        add(PlanEdge(x, r.y, horizontal: true));
        add(PlanEdge(x, r.y + r.h, horizontal: true));
      }
      for (var y = r.y; y < r.y + r.h; y++) {
        add(PlanEdge(r.x, y, horizontal: false));
        add(PlanEdge(r.x + r.w, y, horizontal: false));
      }
    }
    return counts;
  }

  Map<String, dynamic> toJson() => {
        'cellule': cell,
        'pieces': [for (final r in rooms) r.toJson()],
        'ouvertures': [for (final o in placedOpenings) o.toJson()],
      };

  factory HousePlan.fromJson(Map<String, dynamic> j) => HousePlan(
        rooms: [
          for (final r in (j['pieces'] as List? ?? const []))
            if (r is Map) PlanRoom.fromJson(Map<String, dynamic>.from(r)),
        ],
        openings: [
          for (final o in (j['ouvertures'] as List? ?? const []))
            if (o is Map) PlanOpening.fromJson(Map<String, dynamic>.from(o)),
        ],
      );
}

class PlanRoom {
  const PlanRoom({required this.name, required this.x, required this.y, required this.w, required this.h});

  final String name;
  final int x;
  final int y;
  final int w;
  final int h;

  bool contains(double cx, double cy) => cx >= x && cx <= x + w && cy >= y && cy <= y + h;

  PlanRoom copyWith({String? name, int? x, int? y, int? w, int? h}) =>
      PlanRoom(name: name ?? this.name, x: x ?? this.x, y: y ?? this.y, w: w ?? this.w, h: h ?? this.h);

  Map<String, dynamic> toJson() => {'nom': name, 'x': x, 'y': y, 'l': w, 'h': h};

  factory PlanRoom.fromJson(Map<String, dynamic> j) => PlanRoom(
        name: (j['nom'] ?? 'Pièce').toString(),
        x: (j['x'] as num? ?? 0).round(),
        y: (j['y'] as num? ?? 0).round(),
        w: (j['l'] as num? ?? 1).round(),
        h: (j['h'] as num? ?? 1).round(),
      );
}

enum OpeningKind { door, window }

/// A 50 cm wall segment: from (x, y) going right when [horizontal], down otherwise.
class PlanEdge {
  const PlanEdge(this.x, this.y, {required this.horizontal});

  final int x;
  final int y;
  final bool horizontal;

  @override
  bool operator ==(Object other) =>
      other is PlanEdge && other.x == x && other.y == y && other.horizontal == horizontal;

  @override
  int get hashCode => Object.hash(x, y, horizontal);

  @override
  String toString() => '${horizontal ? 'h' : 'v'}$x,$y';
}

class PlanOpening {
  const PlanOpening({required this.kind, required this.edge});

  final OpeningKind kind;
  final PlanEdge edge;

  Map<String, dynamic> toJson() => {
        'type': kind == OpeningKind.door ? 'porte' : 'fenetre',
        'x': edge.x,
        'y': edge.y,
        'horizontal': edge.horizontal,
      };

  factory PlanOpening.fromJson(Map<String, dynamic> j) => PlanOpening(
        kind: j['type'] == 'fenetre' ? OpeningKind.window : OpeningKind.door,
        edge: PlanEdge(
          (j['x'] as num? ?? 0).round(),
          (j['y'] as num? ?? 0).round(),
          horizontal: j['horizontal'] != false,
        ),
      );
}
