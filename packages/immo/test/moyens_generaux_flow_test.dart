import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/construction/screens/moyens_generaux/achats.screen.dart';

/// Moyens généraux' Achats tab at phone size against a fake backend.
void main() {
  http.Response ok(Map<String, dynamic> body) => http.Response(
        jsonEncode({'hasError': false, 'status': {'code': '800', 'message': 'ok'}, ...body}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  test('a backend niveau d’accès opens the matching view', () {
    expect(ConstructionRole.fromAccessLevel('SUPERVISEUR'), ConstructionRole.superviseur);
    expect(ConstructionRole.fromAccessLevel('MOYEN_GENERAUX'), ConstructionRole.moyensGeneraux);
    expect(ConstructionRole.fromAccessLevel('CHEF_CHANTIER'), ConstructionRole.chefSite);
    expect(ConstructionRole.fromAccessLevel('ADMIN_ENTREPRISE'), ConstructionRole.chefSite);
    expect(ConstructionRole.fromAccessLevel('LOCATAIRE'), isNull);
    expect(ConstructionRole.fromAccessLevel(null), isNull);
  });

  testWidgets('Moyens généraux order a validated demande from a chosen supplier', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final states = {'d1': 'validé_superviseur', 'd2': 'envoyé_fournisseur', 'd3': 'validé_superviseur'};
    Map<String, dynamic>? orderBody;
    Map<String, dynamic> demande(String id) => {
          'demandesId': id,
          'titre': id == 'd3' ? 'Acompte location grue' : 'Matériaux — ${id == 'd1' ? 'Villa Bingerville' : 'Duplex Cocody'}',
          'etat': states[id],
          'categorie': id == 'd3' ? 'FINANCIAL' : 'MATERIAL',
          'budgetEstime': 3498800,
          'chantierNom': id == 'd1' ? 'Villa Bingerville' : id == 'd2' ? 'Duplex Cocody' : 'Résidence Riviera',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'fournisseurNom': id == 'd2' || (id == 'd1' && states['d1'] == 'envoyé_fournisseur') ? 'Matériaux Plus CI' : null,
          'lignes': [
            {'libelle': 'Ciment', 'quantite': 228, 'unite': 'sac', 'montant': 1254000},
            {'libelle': 'Fer à béton HA10', 'quantite': 110, 'unite': 'barre', 'montant': 495000},
          ],
        };

    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/mg') return ok({'items': []});
      if (path == '/api/demandes/entreprise/mg') return ok({'items': [for (final id in states.keys) demande(id)]});
      if (path == '/api/demandes/fournisseurs') {
        return ok({
          'items': [
            {'fournisseursId': 'f1', 'nom': 'Quincaillerie Adjamé', 'specialites': 'Fer, outillage', 'evaluationQualite': 3},
            {'fournisseursId': 'f2', 'nom': 'Matériaux Plus CI', 'specialites': 'Ciment, fer, agrégats', 'evaluationQualite': 4},
          ],
        });
      }
      if (req.method == 'POST' && path == '/api/demandes/d1/commande') {
        orderBody = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        states['d1'] = 'envoyé_fournisseur';
        return ok({'item': demande('d1')});
      }
      return http.Response('not found', 404);
    });

    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('mg'));
    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(
        accent: ImmoBrand.constructionPrimary,
        child: Scaffold(body: AchatsScreen(store: store)),
      ),
    ));
    await settle(tester);

    expect(find.text('Villa Bingerville'), findsOneWidget);
    expect(find.text('Résidence Riviera'), findsNothing); // financial: the caisse's, not a supplier's
    expect(find.text('Commandées'), findsOneWidget);

    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.text('Fournisseur'), findsOneWidget);
    await tester.ensureVisible(find.text('Matériaux Plus CI'));
    await tester.tap(find.text('Matériaux Plus CI'));
    await settle(tester);
    final button = find.text('Commander chez Matériaux Plus CI');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await settle(tester);
    expect(find.text('Commander chez Matériaux Plus CI ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Commander'));
    await settle(tester);

    expect(orderBody, {'userId': 'mg', 'fournisseursId': 'f2'});
    expect(find.text('Commande envoyée à Matériaux Plus CI'), findsOneWidget);
    expect(find.text('Rien à commander'), findsOneWidget);
    expect(find.text('Commandée'), findsNWidgets(2));
  });
}
