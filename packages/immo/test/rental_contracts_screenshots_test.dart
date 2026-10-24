import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/immo.dart';
import 'package:immo/src/features/rental/auth/rental.session.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/creation/wizards/create_tenant.wizard.dart';
import 'package:immo/src/features/rental/screens/contract_detail.screen.dart';
import 'package:immo/src/features/rental/screens/contracts.screen.dart';

/// Phone-size screenshots of the lease screens with the app's fonts. Off by default; run with
/// `IMMO_SCREENSHOTS=<folder> FLUTTER_ROOT=<flutter sdk> flutter test test/rental_contracts_screenshots_test.dart`
void main() {
  final outDir = Platform.environment['IMMO_SCREENSHOTS'];
  final boundary = GlobalKey();
  final now = DateTime.now();
  String day(int offset) => now.add(Duration(days: offset)).toIso8601String().substring(0, 10);

  setUpAll(() async {
    if (outDir == null) return;
    Directory(outDir).createSync(recursive: true);
    await _loadFonts();
  });

  http.Response ok(Map<String, dynamic> body) => http.Response(
        jsonEncode({'hasError': false, 'status': {'code': '800', 'message': 'ok'}, ...body}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> lease(String id, String statut, String bien, String tenant,
          {bool tenantSigned = false, bool ownerSigned = false, bool termination = false}) =>
      {
        'contratsLocationId': id,
        'numeroContrat': 'CONTLOC-2026-0000${id.substring(1)}',
        'statut': statut,
        'utilisateursId': 'u1',
        'biens': {'nom': bien, 'adresse': 'Plateau', 'ville': 'Abidjan'},
        'locataires': {'prenoms': tenant.split(' ').first, 'nom': tenant.split(' ').last, 'telephone': '07 00 00 00 01'},
        'dateDebut': day(-30),
        'dateFin': day(335),
        'loyerMensuel': 250000,
        'caution': 500000,
        'modePaiement': 'mobile_money',
        'periodicite': 'mensuel',
        if (tenantSigned) 'dateSignatureLocataire': '${day(-2)}T10:00:00',
        if (ownerSigned) 'dateSignatureProprietaire': '${day(-1)}T11:00:00',
        if (termination) ...{
          'resiliationDemandee': true,
          'dateFinDemandee': '${day(60)}T00:00:00',
          'raisonResiliation': 'Mutation professionnelle à Bouaké',
          'dateDemandeResiliation': '${day(-3)}T09:00:00',
          'approbationProprietaireResiliation': false,
        },
      };

  final leases = {
    'c1': lease('c1', 'en attente', 'Appartement Plateau', 'Marie Dupont', tenantSigned: true),
    'c2': lease('c2', 'signé', 'Villa Riviera 3', 'Kouassi Yao', tenantSigned: true, ownerSigned: true, termination: true),
    'c3': lease('c3', 'signé', 'Studio Cocody', 'Aïcha Bamba', tenantSigned: true, ownerSigned: true),
    'c4': lease('c4', 'annulé', 'Duplex Marcory', 'Jean Koné'),
  };

  Future<http.Response> backend(http.Request req) async {
    final path = req.url.path;
    if (path == '/api/locataires/create') return ok({'item': {'locatairesId': 't9'}});
    // The tenant is created, its lease is not: the wizard's warning dialog
    if (path == '/api/contratslocation/create') {
      return http.Response(
        jsonEncode({'hasError': true, 'status': {'code': '500', 'message': 'Le bien est déjà loué.'}}),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (path == '/api/contratslocation/getByCriteria') return ok({'items': leases.values.toList()});
    if (path.startsWith('/api/contratslocation/')) return ok({'item': leases[path.split('/').last]});
    if (path == '/api/biens/getByCriteria') {
      return ok({
        'items': [
          {'biensId': 'b1', 'nom': 'Appartement Plateau', 'adresse': 'Plateau', 'ville': 'Abidjan', 'prix': 250000},
        ],
      });
    }
    return http.Response('not found', 404);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final box = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: tester.view.devicePixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(const SizedBox()); // a fresh app: no sheet left open from the last screen
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);
    final session = RentalSession(
      api: RentalApiService(client: ImmoApiClient(baseUrl: 'http://demo', httpClient: MockClient(backend))),
    )..signInForTest('u1');
    addTearDown(session.dispose);
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Urbanist'),
        home: RentalSessionScope(session: session, child: ImmoRentalTheme(child: Scaffold(body: screen))),
      ),
    ));
    await settle(tester);
  }

  testWidgets('Lease screenshots', skip: outDir == null, (tester) async {
    debugDisableShadows = false;
    try {
      await pump(tester, ContractsScreen(onBack: () {}, onViewContract: (_) {}));
      await shot(tester, '30-location-documents');

      await pump(tester, ContractDetailScreen(contractId: 'c1', onBack: () {}));
      await shot(tester, '31-location-contrat-a-signer');
      final sign = find.text('Signer le contrat');
      await tester.scrollUntilVisible(sign, 300, scrollable: find.byType(Scrollable).first);
      await settle(tester);
      await shot(tester, '32-location-contrat-a-signer-bas');
      await tester.tap(sign);
      await settle(tester);
      final pad = tester.getRect(find.text('Signez ici avec le doigt'));
      final gesture = await tester.startGesture(pad.center + const Offset(-110, 20));
      for (var i = 1; i <= 24; i++) {
        await gesture.moveBy(Offset(9, (i.isEven ? -1 : 1) * (6 + i % 5 * 3).toDouble()));
      }
      await gesture.up();
      await tester.tap(find.byTooltip('4 étoiles'));
      await settle(tester);
      await shot(tester, '33-location-signature');

      // The same sheet in dark mode: the pad follows the theme
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pump(tester, ContractDetailScreen(contractId: 'c1', onBack: () {}));
      await tester.scrollUntilVisible(find.text('Signer le contrat'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Signer le contrat'));
      await settle(tester);
      final darkPad = tester.getRect(find.text('Signez ici avec le doigt'));
      await shot(tester, '33b-location-signature-sombre-vide');
      final darkGesture = await tester.startGesture(darkPad.center + const Offset(-110, 20));
      for (var i = 1; i <= 24; i++) {
        await darkGesture.moveBy(Offset(9, (i.isEven ? -1 : 1) * (6 + i % 5 * 3).toDouble()));
      }
      await darkGesture.up();
      await tester.tap(find.byTooltip('4 étoiles'));
      await settle(tester);
      await shot(tester, '33c-location-signature-sombre');
      tester.platformDispatcher.clearPlatformBrightnessTestValue();

      await pump(tester, ContractDetailScreen(contractId: 'c2', onBack: () {}));
      await shot(tester, '34-location-resiliation');
      await tester.tap(find.text('Accepter la résiliation'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Bonne continuation, état des lieux le 15.');
      await settle(tester);
      await shot(tester, '35-location-resiliation-accepter');

      await pump(tester, CreateTenantWizard(onClose: () {}));
      for (final (label, text) in [('Nom *', 'Kouassi'), ('Prénom(s) *', 'Awa'), ('Email *', 'awa@demo.ci'), ('Mot de passe *', 'Motdepasse1')]) {
        await tester.enterText(_field(label), text);
      }
      await tester.pump();
      await tester.tap(find.text('Suivant').hitTestable());
      await settle(tester);
      await tester.enterText(_field('Téléphone *'), '0700000009');
      await tester.enterText(_field('CNI *'), 'CI0012345');
      await tester.pump();
      await tester.tap(find.text('Suivant').hitTestable());
      await settle(tester);
      await tester.enterText(_field('Loyer mensuel (FCFA) *'), '250000');
      await tester.enterText(_field('Caution (FCFA)'), '500000');
      await settle(tester);
      await shot(tester, '36-location-assistant-contrat');
      await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -600));
      await settle(tester);
      await shot(tester, '37-location-assistant-contrat-bas');
      await tester.enterText(_field('Début du bail (AAAA-MM-JJ) *'), '2026-11-01');
      await tester.enterText(_field('Fin du bail (AAAA-MM-JJ) *'), '2027-10-31');
      await tester.pump();
      await tester.tap(find.text('Suivant').hitTestable());
      await settle(tester);
      await tester.tap(find.text('Créer le locataire').hitTestable());
      await settle(tester);
      await settle(tester);
      await shot(tester, '38-location-assistant-contrat-echec');
    } finally {
      debugDisableShadows = true;
    }
  });
}

Finder _field(String label) => find
    .descendant(
      of: find.ancestor(of: find.text(label, findRichText: true), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    )
    .first;

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async => ByteData.sublistView(File(path).readAsBytesSync());
  final urbanist = FontLoader('Urbanist');
  for (final f in Directory('../../app/assets/fonts/urbanist').listSync().whereType<File>()) {
    if (f.path.endsWith('.ttf') && !f.path.contains('Italic')) urbanist.addFont(bytes(f.path));
  }
  await urbanist.load();
  final fonts = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  await (FontLoader('MaterialIcons')..addFont(bytes('$fonts/MaterialIcons-Regular.otf'))).load();
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(bytes('$fonts/Roboto-$w.ttf'));
  }
  await roboto.load();
}
