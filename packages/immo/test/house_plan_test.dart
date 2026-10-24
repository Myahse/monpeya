import 'package:flutter_test/flutter_test.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/construction/models/house_plan.model.dart';

void main() {
  // Two rooms side by side: 6 × 5 m and 4 × 5 m (grid cells are 50 cm).
  const left = PlanRoom(name: 'Séjour', x: 2, y: 2, w: 12, h: 10);
  const right = PlanRoom(name: 'Chambre', x: 14, y: 2, w: 8, h: 10);

  test('a shared wall is interior, the outline is exterior', () {
    const plan = HousePlan(rooms: [left, right]);
    final w = plan.walls();
    expect(w.exterior, 30); // 10 × 5 m outline
    expect(w.interior, 5); // the 5 m wall between them
    expect(plan.floorArea, 50);
    expect(plan.bounds, (length: 10.0, width: 5.0));
  });

  test('an L-shape keeps its own outline and area, not its rectangle', () {
    const plan = HousePlan(rooms: [
      PlanRoom(name: 'Séjour', x: 0, y: 0, w: 20, h: 12), // 10 × 6 m
      PlanRoom(name: 'Chambre', x: 0, y: 12, w: 8, h: 8), // 4 × 4 m below
    ]);
    final input = plan.toInput(const MetreInput(length: 0, width: 0));
    expect(input.length, 10);
    expect(input.width, 10);
    expect(input.footprintArea, 76);
    expect(input.exteriorWalls, 40);
    expect(input.interiorWalls, 4);
    expect(input.rooms.map((r) => r.area), [60, 16]);
  });

  test('doors and windows sit on walls and vanish with them', () {
    const door = PlanOpening(kind: OpeningKind.door, edge: PlanEdge(5, 12, horizontal: true));
    const window = PlanOpening(kind: OpeningKind.window, edge: PlanEdge(17, 2, horizontal: true));
    const plan = HousePlan(rooms: [left, right], openings: [door, window]);
    expect(plan.count(OpeningKind.door), 1);
    expect(plan.toInput(const MetreInput(length: 0, width: 0)).windows.count, 1);
    expect(plan.copyWith(rooms: [left]).placedOpenings, [door]);
  });

  test('taps snap to the nearest wall segment', () {
    const plan = HousePlan(rooms: [left]);
    expect(plan.nearestEdge(5.4, 12.1), const PlanEdge(5, 12, horizontal: true));
    expect(plan.nearestEdge(2.1, 6.6), const PlanEdge(2, 6, horizontal: false));
    expect(plan.nearestEdge(8, 7), isNull); // middle of the room
  });

  test('rooms cannot overlap, but may touch', () {
    const plan = HousePlan(rooms: [left]);
    expect(plan.overlaps(right), isFalse);
    expect(plan.overlaps(const PlanRoom(name: '', x: 10, y: 4, w: 6, h: 4)), isTrue);
  });

  test('the drawing survives a save', () {
    const plan = HousePlan(rooms: [left, right], openings: [
      PlanOpening(kind: OpeningKind.window, edge: PlanEdge(2, 4, horizontal: false)),
    ]);
    final back = HousePlan.fromJson(plan.toJson());
    expect(back.rooms.map((r) => r.toJson()), plan.rooms.map((r) => r.toJson()));
    expect(back.openings.single.edge, const PlanEdge(2, 4, horizontal: false));
    expect(back.openings.single.kind, OpeningKind.window);
  });
}
