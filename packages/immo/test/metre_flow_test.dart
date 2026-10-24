import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/construction/models/house_plan.model.dart';
import 'package:immo/src/features/construction/screens/metre.screen.dart';
import 'package:immo/src/features/construction/widgets/plan_editor.widget.dart';
import 'package:immo/src/features/construction/widgets/plan_view_3d.widget.dart';

/// Métré page at phone size against a fake backend: dimensions → materials →
/// adjusted lines → demande.
void main() {
  http.Response ok(Map<String, dynamic> body) => http.Response(
        jsonEncode({'hasError': false, 'status': {'code': '800', 'message': 'ok'}, ...body}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> line(String code, String label, num q, String unit) =>
      {'code': code, 'libelle': label, 'quantite': q, 'unite': unit};

  // What the backend computed for the 12 × 10 m bungalow (see MetreCalculatorTest).
  Map<String, dynamic> metre(Map<String, dynamic> input, {String? demandeId}) => {
        'chantiersId': 's1',
        'donnees': input,
        'demandesId': ?demandeId,
        'updatedAt': DateTime.now().toIso8601String(),
        'resultat': {
          'surfaces': {
            'emprise': 120, 'longueurMursExterieurs': 44, 'longueurMursInterieurs': 16,
            'surfaceMursNette': 153.24, 'surfaceOuvertures': 14.76, 'surfaceSol': 120, 'volumeBeton': 24.23,
          },
          'phases': [
            {'code': 'FONDATIONS', 'libelle': 'Fondations', 'lignes': [line('CIMENT', 'Ciment', 67.5, 'sac')]},
            {'code': 'ELEVATION', 'libelle': 'Élévation des murs', 'lignes': [line('AGGLO_15', 'Agglos 15 × 20 × 40', 2011.28, 'unité')]},
          ],
          'totaux': [
            line('CIMENT', 'Ciment', 228, 'sac'),
            line('SABLE', 'Sable', 21, 'm³'),
            line('AGGLO_15', 'Agglos 15 × 20 × 40', 2012, 'unité'),
            line('PEINTURE', 'Peinture', 90, 'L'),
          ],
          'hypotheses': ['Pertes ajoutées : 5 %.'],
        },
      };

  Finder field(String label, {bool last = false}) {
    final labels = find.text(label);
    return find.descendant(
      of: find.ancestor(of: last ? labels.last : labels.first, matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    // Centre it (at the top edge the row sits under the header), and let the
    // fling stop: a moving list ignores taps. This page has no endless animation.
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await settle(tester);
  }

  testWidgets('Métré: dimensions → materials → demande', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final requests = <http.Request>[];
    Map<String, dynamic>? saved;
    final client = MockClient((req) async {
      requests.add(req);
      final path = req.url.path;
      if (req.method == 'GET' && path == '/api/chantiers/user/u1') {
        return ok({'items': [{'chantiersId': 's1', 'nom': 'Villa Bingerville', 'statut': 'en_cours'}]});
      }
      if (req.method == 'GET' && path == '/api/chantiers/s1/metre') return ok({});
      if (req.method == 'POST' && path == '/api/chantiers/s1/metre') {
        saved = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        return ok({'item': metre(saved!)});
      }
      if (req.method == 'POST' && path == '/api/chantiers/s1/metre/demande') {
        return ok({'item': metre(saved!, demandeId: 'd1')});
      }
      return http.Response('not found: ${req.method} $path', 404);
    });

    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('u1'));
    final site = store.sites.single;

    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(
        accent: ImmoBrand.constructionPrimary,
        child: Scaffold(body: MetreScreen(site: site, store: store, onClose: () {})),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.text('Métré & matériaux'), findsOneWidget);

    // Footprint
    await tester.enterText(field('Longueur'), '12');
    await tester.enterText(field('Largeur'), '10');

    // One room through its sheet
    await tester.tap(find.text('Ajouter'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Ex. Salon, Chambre 1'), 'Salon');
    await tester.enterText(field('Longueur', last: true), '6');
    await tester.enterText(field('Largeur', last: true), '10');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.text('Salon'), findsOneWidget);
    expect(find.text('6 × 10 m · 60 m²'), findsOneWidget);

    // Openings, then compute
    await tester.scrollUntilVisible(find.text('Portes'), 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(field('Portes'), '4');
    await tester.enterText(field('Fenêtres'), '5');
    await tapVisible(tester, find.text('Calculer les matériaux'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    expect(saved!['longueur'], 12.0);
    expect(saved!['largeur'], 10.0);
    expect((saved!['pieces'] as List).single, {'nom': 'Salon', 'longueur': 6.0, 'largeur': 10.0});
    expect(saved!['portes'], {'nombre': 4, 'largeur': 0.9, 'hauteur': 2.1});
    expect(saved!['fenetres']['nombre'], 5);
    expect(saved!['epaisseurAgglo'], 15);

    await tester.scrollUntilVisible(find.text('228 sacs de 50 kg'), 200, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('2 012 agglos'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('2 012 agglos'), findsOneWidget);

    // Cement price → amount; paint left out
    await tapVisible(tester, find.text('Ciment'));
    await tester.enterText(field('Prix unitaire'), '5500');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.text('228 sacs de 50 kg · 1 254 000 FCFA'), findsOneWidget);

    await tapVisible(tester, find.text('Peinture'));
    await tester.enterText(field('Quantité'), '0');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.text('0 L · exclu de la demande'), findsOneWidget);

    // Send
    await tapVisible(tester, find.text('Créer la demande de matériaux'));
    expect(find.text('Envoyer la demande ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Envoyer'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    final post = requests.lastWhere((r) => r.url.path.endsWith('/metre/demande'));
    final data = (jsonDecode(post.body) as Map)['data'] as Map;
    expect(data['userId'], 'u1');
    final lines = (data['lignes'] as List).cast<Map>();
    expect(lines.map((l) => l['code']), ['CIMENT', 'SABLE', 'AGGLO_15']);
    expect(lines.first['quantite'], 228);
    expect(lines.first['prixUnitaire'], 5500.0);
    expect(find.text('Demande envoyée au superviseur'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Demande envoyée'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Demande envoyée'), findsOneWidget);
  });

  testWidgets('Plan: draw two rooms, a door and a window', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Map<String, dynamic>? saved;
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/u1') {
        return ok({'items': [{'chantiersId': 's1', 'nom': 'Villa Bingerville', 'statut': 'en_cours'}]});
      }
      if (req.method == 'GET' && path == '/api/chantiers/s1/metre') return ok({});
      if (req.method == 'POST' && path == '/api/chantiers/s1/metre') {
        saved = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        return ok({'item': metre(saved!)});
      }
      return http.Response('not found', 404);
    });
    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('u1'));
    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(
        accent: ImmoBrand.constructionPrimary,
        child: Scaffold(body: MetreScreen(site: store.sites.single, store: store, onClose: () {})),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    await tester.tap(find.text('Plan'));
    await settle(tester);
    // Read the canvas each time: it must not move, but a test should not assume it.
    Offset at(double x, double y) {
      final canvas = tester.getRect(find.byType(PlanEditor));
      final cell = canvas.width / HousePlan.columns;
      return canvas.topLeft + Offset(x * cell, y * cell);
    }
    final firstTop = tester.getRect(find.byType(PlanEditor)).top;

    // 6 × 5 m, then 4 × 5 m against it
    await tester.dragFrom(at(2, 2), at(14, 12) - at(2, 2));
    await settle(tester);
    expect(find.text('Nouvelle pièce'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);

    await tester.dragFrom(at(14, 2), at(22, 12) - at(14, 2));
    await settle(tester);
    await tester.enterText(
      find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)).first,
      'Chambre',
    );
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.text('Pièce 1'), findsOneWidget);
    expect(find.text('Chambre'), findsOneWidget);
    expect(tester.getRect(find.byType(PlanEditor)).top, firstTop);

    await tester.tap(find.text('Porte'));
    await settle(tester);
    await tester.tapAt(at(5.5, 12));
    await settle(tester);
    await tester.tap(find.text('Fenêtre'));
    await settle(tester);
    await tester.tapAt(at(18, 2));
    await settle(tester);
    expect(
      find.text('1 carreau = 1 m · emprise 50 m² · murs ext. 30 m · int. 5 m · 1 portes · 1 fenêtres'),
      findsOneWidget,
    );

    // The drawing in 3D follows the levels typed under Élévation
    await tester.ensureVisible(find.text('Vue 3D', skipOffstage: false));
    await settle(tester);
    expect(find.text('Glissez pour tourner la maison.'), findsOneWidget);
    expect(tester.widget<PlanView3D>(find.byType(PlanView3D)).levels, 1);
    final levels = find.widgetWithText(TextField, '1', skipOffstage: false);
    await tester.ensureVisible(levels);
    await settle(tester);
    await tester.enterText(levels, '2');
    await settle(tester);
    expect(tester.widget<PlanView3D>(find.byType(PlanView3D)).levels, 2);

    // Dragging over the canvas draws, so scroll to the button without a drag.
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first);
    list.position.jumpTo(list.position.maxScrollExtent);
    await tester.pump();
    await tester.ensureVisible(find.text('Calculer les matériaux', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculer les matériaux'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    expect(saved!['longueur'], 10.0);
    expect(saved!['largeur'], 5.0);
    expect(saved!['longueurMursExterieurs'], 30.0);
    expect(saved!['longueurMursInterieurs'], 5.0);
    expect(saved!['surfaceEmprise'], 50.0);
    expect(saved!['portes']['nombre'], 1);
    expect(saved!['fenetres']['nombre'], 1);
    expect([for (final p in saved!['pieces'] as List) p['nom']], ['Pièce 1', 'Chambre']);
    expect((saved!['plan']['ouvertures'] as List), hasLength(2));
  });
}
