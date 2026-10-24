import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/rental/auth/rental.session.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/creation/wizards/create_tenant.wizard.dart';
import 'package:immo/src/features/rental/models/create_tenant.draft.dart';
import 'package:immo/src/features/rental/screens/contract_detail.screen.dart';
import 'package:immo/src/features/rental/screens/contracts.screen.dart';
import 'package:immo/src/features/rental/utils/rental_format.util.dart';

/// Mes documents and a lease's detail against a fake backend, at phone size.
void main() {
  final now = DateTime.now();
  String day(int offset) => now.add(Duration(days: offset)).toIso8601String().substring(0, 10);

  http.Response ok(Map<String, dynamic> body) => http.Response(
        jsonEncode({'hasError': false, 'status': {'code': '800', 'message': 'ok'}, ...body}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  http.Response refused(String message) => http.Response(
        jsonEncode({'hasError': true, 'status': {'code': '500', 'message': message}}),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> lease(
    String id,
    String statut, {
    bool tenantSigned = false,
    bool ownerSigned = false,
    bool terminationRequested = false,
  }) =>
      {
        'contratsLocationId': id,
        'numeroContrat': 'CONTLOC-2026-0000${id.substring(1)}',
        'statut': statut,
        'utilisateursId': 'u1',
        'biensId': 'b1',
        'biens': {'nom': 'Appartement Plateau', 'adresse': 'Plateau', 'ville': 'Abidjan'},
        'locatairesId': 't1',
        'locataires': {'prenoms': 'Marie', 'nom': 'Dupont', 'telephone': '0700000001'},
        'dateDebut': day(-30),
        'dateFin': day(335),
        'loyerMensuel': 250000,
        'caution': 500000,
        'modePaiement': 'mobile_money',
        'periodicite': 'mensuel',
        'urlPdf': '/api/contratslocation/$id/pdf',
        if (tenantSigned) 'dateSignatureLocataire': '${day(-2)}T10:00:00',
        if (ownerSigned) 'dateSignatureProprietaire': '${day(-1)}T11:00:00',
        if (terminationRequested) ...{
          'resiliationDemandee': true,
          'dateFinDemandee': '${day(60)}T00:00:00',
          'raisonResiliation': 'Mutation professionnelle',
          'dateDemandeResiliation': '${day(-3)}T09:00:00',
          'approbationProprietaireResiliation': false,
        },
      };

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> pump(WidgetTester tester, MockClient client, Widget screen, {double width = 1170}) async {
    tester.view.physicalSize = Size(width, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = RentalSession(
      api: RentalApiService(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client)),
    )..signInForTest('u1');
    addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(
      home: RentalSessionScope(
        session: session,
        child: ImmoRentalTheme(child: Scaffold(body: screen)),
      ),
    ));
    await settle(tester);
  }

  testWidgets('Mes documents lists the owner’s leases by what they need', (tester) async {
    Map<String, dynamic>? criteria;
    final client = MockClient((req) async {
      if (req.url.path == '/api/contratslocation/getByCriteria') {
        criteria = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        return ok({
          'items': [
            lease('c1', 'en attente', tenantSigned: true),
            lease('c2', 'signé', tenantSigned: true, ownerSigned: true, terminationRequested: true),
            lease('c3', 'annulé'),
          ],
        });
      }
      return http.Response('not found', 404);
    });
    String? opened;
    await pump(tester, client, ContractsScreen(onBack: () {}, onViewContract: (id) => opened = id));

    expect(criteria, {'utilisateursId': 'u1'});
    expect(find.text('À signer'), findsWidgets);
    expect(find.text('Actifs'), findsOneWidget);
    expect(find.text('Autres'), findsOneWidget);
    expect(find.text('Résiliation demandée'), findsOneWidget);
    expect(find.text('Annulé'), findsOneWidget);
    expect(find.text('Contrat n° CONTLOC-2026-00001'), findsOneWidget);
    expect(find.text('Locataire · Marie Dupont'), findsNWidgets(3));

    await tester.tap(find.text('Contrat n° CONTLOC-2026-00001'));
    expect(opened, 'c1');
  });

  testWidgets('The owner signs a lease and rates the tenant', (tester) async {
    var signed = false;
    Map<String, dynamic>? signature;
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/contratslocation/c1') {
        return ok({'item': lease('c1', signed ? 'signé' : 'en attente', tenantSigned: true, ownerSigned: signed)});
      }
      if (req.method == 'POST' && path == '/api/contratslocation/signByOwner') {
        signature = jsonDecode(req.body) as Map<String, dynamic>;
        signed = true;
        return ok({'item': lease('c1', 'signé', tenantSigned: true, ownerSigned: true)});
      }
      return http.Response('not found', 404);
    });
    await pump(tester, client, ContractDetailScreen(contractId: 'c1', onBack: () {}));

    expect(find.text('À signer'), findsOneWidget);
    expect(find.text('250 000 FCFA'), findsOneWidget);
    expect(find.text('Mobile money · Mensuel'), findsOneWidget);
    final sign = find.text('Signer le contrat');
    await tester.scrollUntilVisible(sign, 300, scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(find.textContaining('Signé le'), findsOneWidget, reason: 'the tenant signed, the owner not yet');
    expect(find.text('En attente'), findsOneWidget);
    await tester.tap(sign);
    await settle(tester);
    expect(find.text('Signez et notez le locataire pour continuer.'), findsOneWidget);

    final pad = find.text('Signez ici avec le doigt');
    await tester.drag(pad, const Offset(120, 30));
    await tester.drag(find.byType(CustomPaint).last, const Offset(-60, 20));
    await tester.tap(find.byTooltip('3 étoiles'));
    await tester.enterText(find.byType(TextField), 'Locataire sérieux');
    await tester.pump();
    expect(find.text('Signez et notez le locataire pour continuer.'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Signer'));
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Signer'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await settle(tester);
    await settle(tester);

    expect(signature?['contratsLocationId'], 'c1');
    expect(signature?['tenantRating'], 3);
    expect(signature?['ratingComment'], 'Locataire sérieux');
    expect(signature?['signatureData'] as String, startsWith('data:image/png;base64,iVBOR'));
    expect(find.text('Contrat signé'), findsOneWidget);
    expect(find.text('Signer le contrat'), findsNothing);
    expect(find.textContaining('Signé le'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('Actif'), -300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Actif'), findsOneWidget);
  });

  testWidgets('The owner accepts an early termination with a note', (tester) async {
    var answered = false;
    Map<String, dynamic>? answer;
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/contratslocation/c2') {
        return ok({
          'item': {
            ...lease('c2', answered ? 'résilié' : 'signé', tenantSigned: true, ownerSigned: true, terminationRequested: true),
            if (answered) 'approbationProprietaireResiliation': true,
          },
        });
      }
      if (req.method == 'POST' && path == '/api/contracts/c2/approve-termination') {
        answer = jsonDecode(req.body) as Map<String, dynamic>;
        answered = true;
        return ok({'item': 'approved'});
      }
      return http.Response('not found', 404);
    });
    await pump(tester, client, ContractDetailScreen(contractId: 'c2', onBack: () {}));

    expect(find.text('Résiliation demandée'), findsOneWidget);
    expect(find.text('Demande de résiliation'), findsOneWidget);
    expect(find.text('Mutation professionnelle'), findsOneWidget);

    await tester.tap(find.text('Accepter la résiliation'));
    await settle(tester);
    expect(find.text('Accepter la résiliation ?'), findsOneWidget);
    expect(find.textContaining('Le bail prendra fin le'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bonne continuation');
    await tester.tap(find.widgetWithText(FilledButton, 'Accepter'));
    await settle(tester);
    await settle(tester);

    expect(answer, {'approved': true, 'notes': 'Bonne continuation'});
    expect(find.text('Résiliation acceptée'), findsOneWidget);
    expect(find.text('Résilié'), findsOneWidget);
    expect(find.text('Demande de résiliation'), findsNothing);
  });

  testWidgets('A refused answer keeps the sheet open with the reason', (tester) async {
    final answered = Completer<void>();
    final client = MockClient((req) async {
      if (req.url.path == '/api/contratslocation/c2') {
        return ok({'item': lease('c2', 'signé', tenantSigned: true, ownerSigned: true, terminationRequested: true)});
      }
      if (req.url.path == '/api/contracts/c2/approve-termination') {
        await answered.future;
        return refused('Aucune demande de résiliation en cours pour ce contrat');
      }
      return http.Response('not found', 404);
    });
    await pump(tester, client, ContractDetailScreen(contractId: 'c2', onBack: () {}));

    await tester.tap(find.text('Refuser'));
    await settle(tester);
    expect(find.text('Refuser la résiliation ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Refuser').last);
    await tester.pump();
    // On its way: the outlined button spins too
    expect(find.descendant(of: find.byType(OutlinedButton).last, matching: find.byType(CircularProgressIndicator)), findsOneWidget);
    answered.complete();
    await settle(tester);

    expect(find.text('Aucune demande de résiliation en cours pour ce contrat'), findsOneWidget);
    expect(find.text('Refuser la résiliation ?'), findsOneWidget);
  });

  // A required field's label reads "Nom *"
  Finder field(String label) {
    final required = find.text('$label *', findRichText: true);
    final text = required.evaluate().isNotEmpty ? required : find.text(label, findRichText: true);
    return find
        .descendant(
          of: find.ancestor(of: text, matching: find.byType(Column)).first,
          matching: find.byType(TextField),
        )
        .first;
  }

  // Typing needs no scrolling: scrolling here would also slide the step pager
  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  Future<void> next(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).hitTestable());
    await settle(tester);
  }

  /// The tenant's two steps, then the lease terms up to its end date.
  Future<void> fillUpToLeaseEnd(WidgetTester tester) async {
    await type(tester, 'Nom', 'Kouassi');
    await type(tester, 'Prénom(s)', 'Awa');
    await type(tester, 'Email', 'awa@demo.ci');
    await type(tester, 'Mot de passe', 'motdepasse1');
    await next(tester, 'Suivant');
    await type(tester, 'Téléphone', '0700000009');
    await type(tester, 'CNI', 'CI0012345');
    await next(tester, 'Suivant');
    await type(tester, 'Loyer mensuel (FCFA)', '250000');
    await type(tester, 'Caution (FCFA)', '500 000');
    await type(tester, 'Début du bail (AAAA-MM-JJ)', '2026-11-01');
  }

  MockClient wizardBackend({
    void Function(Map<String, dynamic>)? onTenant,
    void Function(Map<String, dynamic>)? onContract,
    http.Response? contractResponse,
  }) =>
      MockClient((req) async {
        final path = req.url.path;
        if (path == '/api/biens/getByCriteria') {
          return ok({
            'items': [
              {'biensId': 'b1', 'nom': 'Appartement Plateau', 'adresse': 'Plateau', 'ville': 'Abidjan', 'prix': 250000},
            ],
          });
        }
        if (req.method == 'POST' && path == '/api/locataires/create') {
          onTenant?.call((jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>);
          return ok({'item': {'locatairesId': 't9'}});
        }
        if (req.method == 'POST' && path == '/api/contratslocation/create') {
          onContract?.call((jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>);
          return contractResponse ?? ok({'item': lease('c9', 'en attente')});
        }
        return http.Response('not found', 404);
      });

  testWidgets('Creating a tenant creates their lease, waiting for signatures', (tester) async {
    Map<String, dynamic>? tenant;
    Map<String, dynamic>? contract;
    final client = wizardBackend(onTenant: (d) => tenant = d, onContract: (d) => contract = d);
    var closed = false;
    // Wider than a phone: the test font's square glyphs overflow the wizard's footer otherwise
    await pump(tester, client, CreateTenantWizard(onClose: () => closed = true), width: 1800);
    await fillUpToLeaseEnd(tester);

    await type(tester, 'Fin du bail (AAAA-MM-JJ)', '2026-10-31');
    await next(tester, 'Suivant');
    expect(find.text('La fin du bail doit suivre son début.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the error snackbar covers the footer until it goes
    await settle(tester);
    await type(tester, 'Fin du bail (AAAA-MM-JJ)', '2027-10-31');
    await next(tester, 'Suivant');
    await next(tester, 'Créer le locataire');

    expect(tenant?['nom'], 'Kouassi');
    expect(contract, {
      'utilisateursId': 'u1',
      'biensId': 'b1',
      'locatairesId': 't9',
      'dateDebut': '2026-11-01',
      'dateFin': '2027-10-31',
      'loyerMensuel': 250000.0,
      'caution': 500000.0,
      'fraisAgence': 0,
      'modePaiement': 'mobile_money',
      'periodicite': 'mensuel',
    });
    expect(find.text('Le locataire et son contrat ont été créés. Signez le contrat dans Mes documents.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(closed, isTrue);
  });

  testWidgets('When the lease fails, the wizard says so instead of success', (tester) async {
    final client = wizardBackend(contractResponse: refused('Le bien est déjà loué.'));
    await pump(tester, client, CreateTenantWizard(onClose: () {}), width: 1800);
    await fillUpToLeaseEnd(tester);
    await type(tester, 'Fin du bail (AAAA-MM-JJ)', '2027-10-31');
    await next(tester, 'Suivant');
    await next(tester, 'Créer le locataire');

    expect(find.text('Contrat non créé'), findsOneWidget);
    expect(find.text('Le locataire est créé, mais son contrat n’a pas pu l’être : Le bien est déjà loué.'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('Succès !'), findsNothing);
  });

  test('Each request carries the Mon Peya session, read fresh, for Mr Immo to know the user', () async {
    final seen = <String?>[];
    final client = ImmoApiClient(
      baseUrl: 'http://test',
      httpClient: MockClient((req) async {
        seen.add(req.headers['X-MonPeya-Token']);
        return ok({'items': []});
      }),
    );
    var token = 'mp-1';
    client.useMonPeyaToken(() async => token);
    await client.postJson('/api/contratslocation/getByCriteria', body: {'data': {}});
    token = 'mp-2'; // Mon Peya refreshed its session
    await client.getJson('/api/contratslocation/c1');
    client.useMonPeyaToken(null);
    await client.getJson('/api/contratslocation/c1');

    expect(seen, ['mp-1', 'mp-2', null]);
  });

  test('A lease reads its status, terms and PDF link', () async {
    String? asked;
    final api = RentalApiService(
      client: ImmoApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient((req) async {
          asked = '${req.method} ${req.url.path}';
          return ok({'item': {'contratsLocationId': 'c1', 'urlPdf': '/api/contratslocation/c1/pdf?e=1&t=abc'}});
        }),
      ),
    );
    final c = RentalContract.fromBackend(lease('c1', 'en attente', tenantSigned: true));
    expect(c.statusLabel, 'À signer');
    expect(c.isToSign, isTrue);
    expect(c.isActive, isFalse);
    expect(c.title, 'Bail — Appartement Plateau');
    expect(c.propertyAddress, 'Plateau, Abidjan');
    expect((await api.contracts.pdfLink(c)).toString(), 'http://test/api/contratslocation/c1/pdf?e=1&t=abc');
    expect(asked, 'POST /api/contratslocation/c1/pdf-link');
    expect(RentalContract.fromBackend({...lease('c4', 'signé'), 'dateFin': day(-1)}).statusLabel, 'Terminé');
    expect(RentalContract.fromBackend(lease('c5', 'résilié')).statusLabel, 'Résilié');

    expect(formatRentalAmount(250000), '250 000 FCFA');
    expect(formatRentalAmount(null), '—');
    expect(formatRentalDate(DateTime(2026, 10, 23)), '23 oct. 2026');

    final draft = CreateTenantDraft()..paymentFrequency = 'daily';
    expect(draft.contractPeriodicity, 'journalier');
    expect(CreateTenantDraft.amount('250 000'), 250000);
  });
}
