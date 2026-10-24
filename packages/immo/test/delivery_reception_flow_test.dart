import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/construction/screens/construction_work.screen.dart';

/// The chef de chantier checks a delivery on site, at phone size against a fake backend.
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

  final now = DateTime.now();
  final site = {
    'chantiersId': 's1',
    'nom': 'Villa Bingerville',
    'statut': 'en_cours',
    'ville': 'Bingerville',
    'dateDebut': now.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10),
    'dateFinPrevue': now.add(const Duration(days: 240)).toIso8601String().substring(0, 10),
  };

  /// A demande of s1 delivered by its supplier; [state] and [received] follow the reception.
  Map<String, dynamic> demande(String state, {Map<String, int> received = const {}}) => {
        'demandesId': 'd1',
        'titre': 'Matériaux — Villa Bingerville',
        'etat': state,
        'categorie': 'MATERIAL',
        'chantiersId': 's1',
        'chantierNom': 'Villa Bingerville',
        'createdAt': now.subtract(const Duration(days: 6)).toIso8601String(),
        'dateValidation': now.subtract(const Duration(days: 5)).toIso8601String(),
        'fournisseurNom': 'Bâti Plus',
        'numeroCommande': 'CMD-1',
        'dateCommande': now.subtract(const Duration(days: 4)).toIso8601String(),
        'dateExpedition': now.subtract(const Duration(days: 2)).toIso8601String(),
        'dateLivraisonPrevue': now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
        'dateLivraison': now.subtract(const Duration(days: 1)).toIso8601String(),
        if (state != 'livré_chantier') 'dateReception': now.toIso8601String(),
        if (state != 'livré_chantier') 'commentaireReception': '20 sacs manquants',
        'lignes': [
          {'libelle': 'Ciment', 'quantite': 228, 'unite': 'sac', 'commandesId': 'c1', 'quantiteLivree': received['c1'] ?? 228},
          {'libelle': 'Sable', 'quantite': 21, 'unite': 'm³', 'commandesId': 'c2', 'quantiteLivree': received['c2'] ?? 21},
        ],
      };

  Future<void> pump(WidgetTester tester, MockClient client) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('chef'));
    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(
        accent: ImmoBrand.constructionPrimary,
        child: Scaffold(body: ConstructionWorkScreen(role: ConstructionRole.chefSite, store: store)),
      ),
    ));
    await settle(tester);
  }

  Future<void> openDemande(WidgetTester tester) async {
    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.text('Demandes de matériaux'), findsOneWidget);
    expect(find.text('À réceptionner'), findsOneWidget);
    await tester.tap(find.text('Matériaux'));
    await settle(tester);
  }

  testWidgets('Everything arrived: the chef closes the demande', (tester) async {
    var state = 'livré_chantier';
    Map<String, dynamic>? reception;
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/chef') return ok({'items': [site]});
      if (path == '/api/demandes/entreprise/chef') return ok({'items': [demande(state)]});
      if (req.method == 'POST' && path == '/api/demandes/d1/reception') {
        reception = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        state = 'terminé';
        return ok({'item': {'demandesId': 'd1', 'etat': state}});
      }
      return http.Response('not found', 404);
    });
    await pump(tester, client);
    await openDemande(tester);

    // The follow-up, from the order to the check still to do
    expect(find.text('Suivi'), findsOneWidget);
    expect(find.textContaining('Commandée chez Bâti Plus'), findsOneWidget);
    expect(find.textContaining('En route le'), findsOneWidget);
    expect(find.textContaining('Livrée le'), findsOneWidget);
    expect(find.text('Réception par le chef de chantier'), findsOneWidget);

    final all = find.text('Tout est arrivé');
    await tester.ensureVisible(all);
    await tester.tap(all);
    await settle(tester);
    expect(find.text('Tout est arrivé ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
    await settle(tester);
    await settle(tester);

    expect(reception, {'userId': 'chef', 'lignes': <dynamic>[]});
    expect(find.text('Réception enregistrée — la demande est clôturée'), findsOneWidget);
    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.text('Réceptionnée'), findsOneWidget);
  });

  testWidgets('Something is missing: the chef counts what came', (tester) async {
    var state = 'livré_chantier';
    var received = <String, int>{};
    Map<String, dynamic>? reception;
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/chef') return ok({'items': [site]});
      if (path == '/api/demandes/entreprise/chef') return ok({'items': [demande(state, received: received)]});
      if (req.method == 'POST' && path == '/api/demandes/d1/reception') {
        reception = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        state = 'réception_partielle';
        received = {'c1': 208};
        return ok({'item': {'demandesId': 'd1', 'etat': state}});
      }
      return http.Response('not found', 404);
    });
    await pump(tester, client);
    await openDemande(tester);

    final missing = find.text('Il manque quelque chose');
    await tester.ensureVisible(missing);
    await tester.tap(missing);
    await settle(tester);

    final cement = find.widgetWithText(TextField, '228');
    await tester.ensureVisible(cement);
    // More than ordered is refused
    await tester.enterText(cement, '300');
    final confirm = find.text('Confirmer la réception');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(find.text('Saisissez entre 0 et 228 sacs pour « Ciment ».'), findsOneWidget);
    expect(reception, isNull);

    await tester.enterText(find.widgetWithText(TextField, '300'), '208');
    await tester.enterText(find.widgetWithText(TextField, 'Ex. 20 sacs de ciment manquants'), '20 sacs manquants');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(find.text('Confirmer la réception ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
    await settle(tester);
    await settle(tester);

    expect(reception, {
      'userId': 'chef',
      'lignes': [
        {'commandesId': 'c1', 'quantiteRecue': 208},
        {'commandesId': 'c2', 'quantiteRecue': 21},
      ],
      'commentaire': '20 sacs manquants',
    });
    expect(find.text('Réception enregistrée — le manque est signalé'), findsOneWidget);
    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.text('Réception partielle'), findsOneWidget);

    // The demande now says what came short
    await tester.tap(find.text('Matériaux'));
    await settle(tester);
    expect(find.text('228 sacs · reçu 208 sacs'), findsOneWidget);
    expect(find.textContaining('Réception partielle le'), findsOneWidget);
    expect(find.text('« 20 sacs manquants »'), findsOneWidget);
    expect(find.text('Tout est arrivé'), findsNothing);
  });
}
