import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:immo/src/features/construction/models/house_3d.model.dart';
import 'package:immo/src/features/construction/models/house_plan.model.dart';
import 'package:immo/src/features/construction/models/metre.model.dart';
import 'package:immo/src/features/construction/widgets/plan_view_3d.widget.dart';

void main() {
  // One 4 × 3 m room (grid cells are 50 cm), 15 cm blocks, 2.8 m walls.
  const room = PlanRoom(name: 'Chambre', x: 0, y: 0, w: 8, h: 6);
  const t = 0.15;

  double volume(House3D h) => h.walls.fold(0.0, (s, w) => s + w.volume);

  /// The 14 m outline, each run lengthened by a block at both ends, over [height].
  double solid(double height) => (2 * (4 + t) + 2 * (3 + t)) * t * height;

  test('walls stand at their height, on every level', () {
    final one = House3D.of(const HousePlan(rooms: [room]), levels: 1, wallHeight: 2.8);
    final two = House3D.of(const HousePlan(rooms: [room]), levels: 2, wallHeight: 2.8);
    expect(one.height, 2.8);
    expect(two.height, 5.6);
    expect(volume(one), closeTo(solid(2.8), 1e-9));
    expect(volume(two), closeTo(solid(5.6), 1e-9));
    expect(two.walls.map((w) => w.z1).reduce((a, b) => a > b ? a : b), 5.6);
    expect(one.walls.every((w) => w.exterior), isTrue);
    expect(one.rooms, [(name: 'Chambre', x: 0.0, y: 0.0, w: 4.0, h: 3.0)]);
    expect(two.walls.map((w) => w.level).toSet(), {0, 1});
    expect(two.walls.where((w) => w.level == 1).every((w) => w.z0 >= 2.8 - 1e-9), isTrue);
  });

  test('a sheet roof has two slopes along the long side and two gables', () {
    final house = House3D.of(const HousePlan(rooms: [room]), levels: 1, wallHeight: 2.8, flatRoof: false);
    expect(house.roof, hasLength(4));
    expect(house.roof.where((f) => f.gable), hasLength(2));
    final zs = house.roof.expand((f) => f.corners).map((p) => p.z);
    final slope = 0.4663; // tan 25°
    // Ridge: half the 3.15 m outer width above the walls; eaves 0.5 m out and lower.
    expect(zs.reduce((a, b) => a > b ? a : b), closeTo(2.8 + 1.575 * slope, 1e-3));
    expect(zs.reduce((a, b) => a < b ? a : b), closeTo(2.8 - 0.5 * slope, 1e-3));
    // The ridge runs along x, the 4 m side, at the middle of y.
    final ridge = house.roof.first.corners.where((p) => p.z > 3.4);
    expect(ridge.map((p) => p.y).toSet(), {closeTo(1.5, 1e-9)});
    expect(House3D.of(const HousePlan(rooms: [room]), levels: 1, wallHeight: 2.8).roof, isEmpty);
  });

  test('a door and a window are cut out of every floor', () {
    const door = PlanOpening(kind: OpeningKind.door, edge: PlanEdge(3, 6, horizontal: true));
    const window = PlanOpening(kind: OpeningKind.window, edge: PlanEdge(0, 2, horizontal: false));
    final house = House3D.of(
      const HousePlan(rooms: [room], openings: [door, window]),
      levels: 2,
      wallHeight: 2.8,
    );
    const doorHole = 0.9 * 2.1 * t;
    const windowHole = 1.2 * 1.2 * t;
    expect(volume(house), closeTo(solid(5.6) - 2 * (doorHole + windowHole), 1e-9));

    // On each floor the door reaches that floor; the window sits on a sill, its top level with the door's.
    double cm(double m) => (m * 100).roundToDouble() / 100;
    final front = house.walls.where((w) => w.y0 < 3 && w.y1 > 3);
    final atDoor = front.where((w) => w.x0 >= 1.3 - 1e-9 && w.x1 <= 2.2 + 1e-9); // 0.9 m around 1.75 m
    expect(atDoor.map((w) => (cm(w.z0), cm(w.z1))).toSet(), {(2.1, 2.8), (4.9, 5.6)});
    final side = house.walls.where((w) => w.x0 < 0 && w.x1 > 0);
    final atWindow = side.where((w) => w.y0 >= 0.65 - 1e-9 && w.y1 <= 1.85 + 1e-9);
    expect(atWindow.map((w) => (cm(w.z0), cm(w.z1))).toSet(), {(0.0, 0.9), (2.1, 2.8), (2.8, 3.7), (4.9, 5.6)});
  });

  test('a shared wall is interior', () {
    const next = PlanRoom(name: 'Séjour', x: 8, y: 0, w: 8, h: 6);
    final house = House3D.of(const HousePlan(rooms: [room, next]), levels: 1, wallHeight: 2.8);
    final interior = house.walls.where((w) => !w.exterior).toList();
    expect(interior, hasLength(1));
    expect((interior.single.x0, interior.single.x1), (4 - t / 2, 4 + t / 2));
    expect(interior.single.y1 - interior.single.y0, closeTo(3 + t, 1e-9));
  });

  testWidgets('a finger turns the house without scrolling the page under it', (tester) async {
    final input = const HousePlan(rooms: [room]).toInput(const MetreInput(length: 0, width: 0, levels: 2));
    final scroll = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(controller: scroll, children: [
          PlanView3D.ofInput(input),
          const SizedBox(height: 2000),
        ]),
      ),
    ));
    await tester.drag(find.byType(CustomPaint).last, const Offset(80, 60));
    await tester.pump();
    expect(scroll.offset, 0);
    expect(tester.takeException(), isNull);

    // Two fingers pinch to zoom, still without scrolling.
    final centre = tester.getCenter(find.byType(AspectRatio));
    final a = await tester.startGesture(centre - const Offset(20, 0));
    final b = await tester.startGesture(centre + const Offset(20, 0));
    await a.moveBy(const Offset(-60, 30));
    await b.moveBy(const Offset(60, -30));
    await a.up();
    await b.up();
    await tester.pump();
    expect(scroll.offset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choose the whole house, no roof, or one floor', (tester) async {
    Future<void> show(MetreInput input) => tester.pumpWidget(MaterialApp(
          home: Scaffold(body: ListView(children: [PlanView3D.ofInput(input)])),
        ));
    const plan = HousePlan(rooms: [room]);

    await show(plan.toInput(const MetreInput(length: 0, width: 0, levels: 2)));
    for (final label in ['Maison', 'Sans toit', 'RDC', 'R+1']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('R+1'));
    await tester.pump();
    await tester.tap(find.text('Sans toit'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // One level under a terrace: nothing to choose
    await show(plan.toInput(const MetreInput(length: 0, width: 0, flatRoof: true)));
    expect(find.byType(SegmentedButton<int>), findsNothing);
  });
}
