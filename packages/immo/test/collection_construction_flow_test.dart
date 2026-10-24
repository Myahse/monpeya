import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/collection/screens/rent_collection.screen.dart';
import 'package:immo/src/features/construction/screens/construction_work.screen.dart';

/// Renders the Collection (blue) and Construction (orange) flows at phone size
/// against a fake backend, so layout errors and wrong requests fail here.
void main() {
  String iso(DateTime d) => d.toIso8601String();

  http.Response ok(Map<String, dynamic> body) => http.Response(
        jsonEncode({'hasError': false, 'status': {'code': '800', 'message': 'ok'}, ...body}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Color accent) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(accent: accent, child: Scaffold(body: screen)),
    ));
    await settle(tester);
  }

  testWidgets('Collection: mark a late rent paid, then create a schedule', (tester) async {
    final now = DateTime.now();
    final requests = <http.Request>[];
    var latePaid = false;

    final client = MockClient((req) async {
      requests.add(req);
      final path = req.url.path;
      if (req.method == 'GET' && path == '/api/paiements/collection/u1') {
        return ok({
          'items': [
            {
              'paiementsId': 'p-late',
              'montant': 450000,
              'dateEcheance': iso(now.subtract(const Duration(days: 20))),
              'datePaiement': latePaid ? iso(now) : null,
              'statut': latePaid ? 'paid' : 'pending',
              'locatairesId': 't1',
              'locataireNom': 'Awa Koné',
              'biensId': 'b1',
              'bienNom': 'Résidence Akwaba',
            },
            {
              'paiementsId': 'p-next',
              'montant': 450000,
              'dateEcheance': iso(now.add(const Duration(days: 10))),
              'statut': 'pending',
              'locatairesId': 't1',
              'locataireNom': 'Awa Koné',
              'biensId': 'b1',
              'bienNom': 'Résidence Akwaba',
            },
            {
              'paiementsId': 'p-paid',
              'montant': 450000,
              'dateEcheance': iso(now.subtract(const Duration(days: 50))),
              'datePaiement': iso(now.subtract(const Duration(days: 48))),
              'statut': 'paid',
              'methodePaiement': 'Espèces',
              'locatairesId': 't1',
              'locataireNom': 'Awa Koné',
              'biensId': 'b1',
              'bienNom': 'Résidence Akwaba',
            },
          ],
        });
      }
      if (req.method == 'GET' && path == '/api/paiements/collection/u1/tenants') {
        return ok({
          'items': [
            {
              'locatairesId': 't1',
              'nom': 'Awa Koné',
              'biensId': 'b1',
              'bienNom': 'Résidence Akwaba',
              'bienAdresse': 'Cocody, Abidjan',
              'montantLoyer': 450000,
              'frequencePaiement': 'monthly',
              'dateDebutBail': iso(now.subtract(const Duration(days: 90))),
              'dateFinBail': iso(now.add(const Duration(days: 275))),
              'echeancesGenerees': 12,
            },
            {
              'locatairesId': 't2',
              'nom': 'Koffi Yao',
              'biensId': 'b1',
              'bienNom': 'Résidence Akwaba',
              'montantLoyer': 150000,
              'frequencePaiement': 'monthly',
              'dateDebutBail': iso(now),
              'dateFinBail': iso(now.add(const Duration(days: 365))),
              'echeancesGenerees': 0,
            },
          ],
        });
      }
      if (req.method == 'PUT' && path == '/api/paiements/p-late/mark-paid') {
        latePaid = true;
        return ok({});
      }
      if (req.method == 'POST' && path == '/api/paiements/generate/t2') {
        return ok({'items': List.generate(12, (i) => {'paiementsId': 'g$i'})});
      }
      return http.Response('not found: ${req.method} $path', 404);
    });

    final store = CollectionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('u1'));
    await pumpScreen(tester, RentCollectionScreen(store: store), ImmoBrand.collectionPrimary);

    expect(find.text('En retard'), findsWidgets);
    expect(find.text('À venir'), findsOneWidget);
    await scrollTo(tester, find.text('Encaissements'));
    expect(find.text('Échéanciers à créer'), findsOneWidget);
    await scrollTo(tester, find.textContaining('En retard depuis le'), up: true);

    // Late rent → sheet → Mobile money + reference → confirm.
    await tester.tap(find.textContaining('En retard depuis le'));
    await settle(tester);
    expect(find.text('Encaisser le loyer'), findsOneWidget);
    await tester.tap(find.text('Mobile money'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'REC-42');
    final confirm = find.text('Confirmer l’encaissement');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    final markPaid = requests.singleWhere((r) => r.method == 'PUT');
    expect(markPaid.url.queryParameters['methodePaiement'], 'Mobile money');
    expect(markPaid.url.queryParameters['reference'], 'REC-42');
    expect(find.text('Loyer de Awa Koné encaissé'), findsOneWidget);
    expect(find.text('Encaisser le loyer'), findsNothing);
    // Let that snackbar time out; the next one queues behind it.
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    // Tenant without schedule → confirm → schedule created.
    await scrollTo(tester, find.text('Koffi Yao'));
    await tester.tap(find.text('Koffi Yao'));
    await settle(tester);
    expect(find.text('Créer l’échéancier ?'), findsOneWidget);
    await tester.tap(find.text('Créer'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    final generate = requests.singleWhere((r) => r.method == 'POST');
    expect(generate.url.path, '/api/paiements/generate/t2');
    expect(generate.url.queryParameters['userId'], 'u1');
    expect(find.text('Échéancier créé pour Koffi Yao'), findsOneWidget);
  });

  testWidgets('Construction: hand a chantier over to Location', (tester) async {
    final now = DateTime.now();
    final requests = <http.Request>[];

    Map<String, dynamic> villa({bool handedOver = false}) => {
          'chantiersId': 's1',
          'nom': 'Villa Bingerville',
          'statut': handedOver ? 'terminé' : 'en_cours',
          'ville': 'Bingerville',
          'adresse': 'Bingerville, Abidjan',
          'surfaceM2': 380,
          'budgetAlloue': 120000000,
          'dateDebut': iso(now.subtract(const Duration(days: 90))).substring(0, 10),
          'dateFinPrevue': iso(now.add(const Duration(days: 240))).substring(0, 10),
          if (handedOver) 'biensId': 'b9',
          if (handedOver) 'dateFinReelle': iso(now).substring(0, 10),
          if (handedOver) 'dateOuvertureLocation': iso(now),
        };

    final client = MockClient((req) async {
      requests.add(req);
      final path = req.url.path;
      if (req.method == 'GET' && path == '/api/chantiers/user/u1') {
        return ok({
          'items': [
            villa(),
            {
              'chantiersId': 's2',
              'nom': 'Résidence Riviera',
              'statut': 'terminé',
              'ville': 'Abidjan',
              'biensId': 'b1',
              'dateOuvertureLocation': iso(now.subtract(const Duration(days: 30))),
            },
          ],
        });
      }
      if (req.method == 'POST' && path == '/api/chantiers/s1/handover') {
        return ok({'item': villa(handedOver: true)});
      }
      return http.Response('not found: ${req.method} $path', 404);
    });

    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('u1'));
    await pumpScreen(
      tester,
      ConstructionWorkScreen(role: ConstructionRole.chefSite, store: store),
      ImmoBrand.constructionPrimary,
    );

    expect(find.text('Villa Bingerville'), findsOneWidget);
    expect(find.text('En cours'), findsWidgets);
    expect(find.text('En location'), findsOneWidget);

    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '350 000');
    final handover = find.text('Terminer et passer en location');
    await tester.ensureVisible(handover);
    await tester.tap(handover);
    await settle(tester);
    expect(find.text('Passer en location ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Passer en location'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    final post = requests.singleWhere((r) => r.method == 'POST');
    final body = jsonDecode(post.body) as Map<String, dynamic>;
    expect(body['data'], {'userId': 'u1', 'prix': 350000.0});
    expect(find.textContaining('est passé en location'), findsOneWidget);
    expect(find.text('En location'), findsNWidgets(2));
  });
}

/// Rows below the fold are not built until scrolled to.
Future<void> scrollTo(WidgetTester tester, Finder target, {bool up = false}) async {
  await tester.scrollUntilVisible(
    target,
    up ? -200 : 200,
    scrollable: find.byType(Scrollable).first,
  );
  await settle(tester);
}

/// The empty-state pulse repeats forever, so never pumpAndSettle.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
