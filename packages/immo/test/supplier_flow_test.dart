import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/construction/screens/supplier/screens/commandes.screen.dart';

/// Supplier's Commandes tab at phone size against a fake backend.
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

  Future<ConstructionStore> pump(WidgetTester tester, MockClient client) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = ConstructionStore(client: ImmoApiClient(baseUrl: 'http://test', httpClient: client));
    addTearDown(store.dispose);
    await tester.runAsync(() => store.load('sup'));
    await tester.pumpWidget(MaterialApp(
      home: ImmoRentalTheme(
        accent: ImmoBrand.constructionPrimary,
        child: Scaffold(body: SupplierOrdersScreen(store: store)),
      ),
    ));
    await settle(tester);
    await settle(tester);
    return store;
  }

  testWidgets('The supplier sets off with an expected day, then confirms the delivery', (tester) async {
    final states = {'d1': 'envoyé_fournisseur', 'd2': 'terminé'};
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final expected = '${tomorrow.year}-${'${tomorrow.month}'.padLeft(2, '0')}-${'${tomorrow.day}'.padLeft(2, '0')}';
    Map<String, dynamic>? shipping;
    Map<String, dynamic>? delivery;
    Map<String, dynamic> order(String id) => {
          'demandesId': id,
          'numeroCommande': 'CMD-261023-${id.toUpperCase()}AAAA-1',
          'dateCommande': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'chantierNom': id == 'd1' ? 'Villa Bingerville' : 'Duplex Cocody',
          'instructionLivraison': 'Livraison au chantier « Villa Bingerville » — Route de Bingerville, Bingerville',
          'transporteur': 'Fournisseur',
          'etat': states[id],
          'dateExpedition': states[id] == 'en_livraison' ? DateTime.now().toIso8601String() : null,
          'dateLivraisonPrevue': states[id] == 'en_livraison' ? expected : null,
          'dateLivraison': states[id] == 'terminé' || states[id] == 'livré_chantier' ? DateTime.now().toIso8601String() : null,
          'montantTotal': 1674000,
          'lignes': [
            {'libelle': 'Ciment', 'quantiteCommandee': 228, 'quantiteLivree': 0, 'unite': 'sac', 'montant': 1254000},
            {'libelle': 'Sable', 'quantiteCommandee': 21, 'quantiteLivree': 0, 'unite': 'm³', 'montant': 420000},
          ],
        };
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/sup') return ok({'items': []});
      if (path == '/api/demandes/fournisseur/sup/commandes') return ok({'items': [order('d1'), order('d2')]});
      if (req.method == 'POST' && path == '/api/demandes/d1/expedition') {
        shipping = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        states['d1'] = 'en_livraison';
        return ok({'item': order('d1')});
      }
      if (req.method == 'POST' && path == '/api/demandes/d1/livraison') {
        delivery = (jsonDecode(req.body) as Map)['data'] as Map<String, dynamic>;
        states['d1'] = 'livré_chantier';
        return ok({'item': order('d1')});
      }
      return http.Response('not found', 404);
    });
    await pump(tester, client);

    expect(find.text('À livrer'), findsWidgets);
    expect(find.text('Livrées'), findsWidgets);
    expect(find.text('Réceptionnée'), findsOneWidget);

    // Sets off, expected tomorrow (the default)
    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.text('228 sacs · 1 254 000 FCFA'), findsOneWidget);
    expect(find.text('Arrivée prévue au chantier'), findsOneWidget);
    final ship = find.text('Mettre en route');
    await tester.ensureVisible(ship);
    await tester.tap(ship);
    await settle(tester);
    expect(shipping, {'userId': 'sup', 'dateLivraisonPrevue': expected});
    expect(find.text('Commande en route'), findsOneWidget);
    expect(find.text('En route'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // that snackbar goes
    await settle(tester);

    // Then delivers it, for the chef de chantier to check
    await tester.tap(find.text('Villa Bingerville'));
    await settle(tester);
    expect(find.textContaining('arrivée prévue le'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Ex. Déchargé au portail, reçu par le gardien'), 'Reçu par le chef');
    final confirm = find.text('Confirmer la livraison');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(find.text('Confirmer la livraison ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
    await settle(tester);

    expect(delivery, {'userId': 'sup', 'commentaire': 'Reçu par le chef'});
    expect(find.text('Livraison confirmée — en attente de réception sur le chantier'), findsOneWidget);
    expect(find.text('Aucune commande à livrer'), findsOneWidget);
  });

  testWidgets('A user with no supplier account sees why', (tester) async {
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/chantiers/user/sup') return ok({'items': []});
      if (path == '/api/demandes/fournisseur/sup/commandes') {
        return http.Response(
          jsonEncode({'hasError': true, 'status': {'code': '907', 'message': 'Aucun compte fournisseur n\'est lié à votre profil'}}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('not found', 404);
    });
    await pump(tester, client);
    expect(find.text('Commandes indisponibles'), findsOneWidget);
    expect(find.text('Aucun compte fournisseur n\'est lié à votre profil'), findsOneWidget);
  });
}
