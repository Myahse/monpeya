import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/construction/screens/superviseur/demandes.screen.dart';
import 'package:immo/src/features/construction/widgets/plan_view_3d.widget.dart';

/// Superviseur's Demandes tab at phone size against a fake backend.
void main() {
  http.Response ok(Map<String, dynamic> body) => http.Response(
        jsonEncode({'hasError': false, 'status': {'code': '800', 'message': 'ok'}, ...body}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> demande(String id, String chantier, String etat, {num budget = 0}) => {
        'demandesId': id,
        'titre': 'Matériaux — $chantier',
        'justification': 'Quantités calculées depuis le métré du 20/10/2026',
        'budgetEstime': budget,
        'urgence': 'NORMAL',
        'etat': etat,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'chantierNom': chantier,
        'lignes': [
          {'libelle': 'Ciment', 'quantite': 228, 'unite': 'sac', 'montant': 1254000},
          {'libelle': 'Agglos 15 × 20 × 40', 'quantite': 2012, 'unite': 'unité', 'montant': 0},
        ],
      };

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Superviseur validates one demande and refuses another with a reason', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final decisions = <Map<String, dynamic>>[];
    final states = {'d1': 'en attente', 'd2': 'en attente', 'd3': 'validé_superviseur'};
    final names = {'d1': 'Villa Bingerville', 'd2': 'Résidence Riviera', 'd3': 'Duplex Cocody'};
    Map<String, dynamic> current(String id) => demande(id, names[id]!, states[id]!, budget: 1254000);

    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/sup') return ok({'items': []});
      if (path == '/api/demandes/entreprise/sup') {
        return ok({'items': [for (final id in states.keys) current(id)]});
      }
      final m = RegExp(r'^/api/demandes/(\w+)/decision$').firstMatch(path);
      if (m != null && req.method == 'POST') {
        final data = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        decisions.add({'id': m.group(1), ...data});
        states[m.group(1)!] = data['decision'] == 'VALIDER' ? 'validé_superviseur' : 'refusé';
        return ok({'item': current(m.group(1)!)});
      }
      return http.Response('not found', 404);
    });

    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('sup'));
    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(
        accent: ImmoBrand.constructionPrimary,
        child: Scaffold(body: DemandesScreen(store: store)),
      ),
    ));
    await settle(tester);

    expect(find.text('À valider'), findsWidgets); // stat + section + chips
    expect(find.text('Traitées'), findsOneWidget);

    // Validate the first one
    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.text('Budget estimé : 1 254 000 FCFA'), findsOneWidget);
    await tester.tap(find.text('Valider la demande'));
    await settle(tester);
    expect(find.text('Valider la demande ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await settle(tester);
    expect(decisions.single, {'id': 'd1', 'userId': 'sup', 'decision': 'VALIDER'});
    expect(find.text('Demande validée — transmise aux moyens généraux'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    // Refuse the second: a reason is required
    await tester.tap(find.text('Résidence Riviera'));
    await settle(tester);
    await tester.tap(find.text('Refuser'));
    await settle(tester);
    await tester.tap(find.text('Confirmer le refus'));
    await settle(tester);
    expect(find.text('Indiquez le motif du refus.'), findsOneWidget);
    expect(decisions, hasLength(1));
    await tester.enterText(find.widgetWithText(TextField, 'Ex. Quantité de fer trop élevée'), 'Trop de fer');
    await tester.tap(find.text('Confirmer le refus'));
    await settle(tester);
    expect(decisions.last, {'id': 'd2', 'userId': 'sup', 'decision': 'REFUSER', 'motif': 'Trop de fer'});
    expect(find.text('Demande refusée'), findsOneWidget);

    // Nothing left to validate
    expect(find.text('Rien à valider'), findsOneWidget);
    expect(find.text('Refusée'), findsOneWidget);
  });

  testWidgets('A demande raised from a drawn métré shows the house in 3D', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Map<String, dynamic> metre(String chantier, String demandeId) => {
          'chantiersId': chantier,
          'demandesId': demandeId,
          'updatedAt': '2026-10-20T09:00:00',
          'donnees': {
            'longueur': 10,
            'largeur': 5,
            'niveaux': 2,
            'hauteurMur': 2.8,
            'plan': {
              'cellule': 0.5,
              'pieces': [
                {'nom': 'Séjour', 'x': 0, 'y': 0, 'l': 12, 'h': 10},
                {'nom': 'Chambre', 'x': 12, 'y': 0, 'l': 8, 'h': 10},
              ],
              'ouvertures': [
                {'type': 'porte', 'x': 5, 'y': 10, 'horizontal': true},
              ],
            },
          },
          'resultat': {},
        };
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/sup') return ok({'items': []});
      if (path == '/api/demandes/entreprise/sup') {
        return ok({
          'items': [
            {...demande('d1', 'Villa Bingerville', 'en attente'), 'chantiersId': 'c1'},
            {...demande('d2', 'Résidence Riviera', 'en attente'), 'chantiersId': 'c2'},
          ],
        });
      }
      // c1's métré raised d1; c2's métré was saved again after d2, for another demande
      if (path == '/api/chantiers/c1/metre') return ok({'item': metre('c1', 'd1')});
      if (path == '/api/chantiers/c2/metre') return ok({'item': metre('c2', 'd9')});
      return http.Response('not found', 404);
    });

    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('sup'));
    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(
        accent: ImmoBrand.constructionPrimary,
        child: Scaffold(body: DemandesScreen(store: store)),
      ),
    ));
    await settle(tester);

    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.text('Vue 3D'), findsOneWidget);
    expect(find.text('Métré du 20/10/2026 · 2 niveaux · murs de 2,8 m. Glissez pour tourner la maison.'), findsOneWidget);
    // Turning the house neither scrolls nor closes the sheet
    await tester.drag(find.byType(PlanView3D), const Offset(0, 300));
    await settle(tester);
    expect(find.text('Valider la demande'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(PlanView3D))).pop();
    await settle(tester);

    await tester.tap(find.text('Résidence Riviera'));
    await settle(tester);
    expect(find.text('Valider la demande'), findsOneWidget);
    expect(find.text('Vue 3D'), findsNothing);
  });
}
