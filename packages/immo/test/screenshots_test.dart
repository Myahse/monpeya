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
import 'package:immo/src/features/construction/screens/metre.screen.dart';
import 'package:immo/src/shared/auth/immo_module.session.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_module_shell.widget.dart';

/// Phone-size screenshots of Collection and Construction with sample data,
/// rendered with the app's real fonts. Off by default; run with
/// `IMMO_SCREENSHOTS=<folder> FLUTTER_ROOT=<flutter sdk> flutter test test/screenshots_test.dart`
void main() {
  final outDir = Platform.environment['IMMO_SCREENSHOTS'];
  final boundary = GlobalKey();

  setUpAll(() async {
    if (outDir == null) return;
    Directory(outDir).createSync(recursive: true);
    await _loadFonts();
  });

  setUp(() => ImmoHostBridge.auth = _DemoHost());
  tearDown(() => ImmoHostBridge.auth = null);

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);
  }

  /// Tests draw shadows as flat outlines by default; draw them as on a phone.
  /// The flag must be back on before the test ends, so not in a tear-down.
  Future<void> withShadows(Future<void> Function() body) async {
    debugDisableShadows = false;
    try {
      await body();
    } finally {
      debugDisableShadows = true;
    }
  }

  /// Lets requests answer, then plays the staggered fade-ins: their timers
  /// start the animations, which need further frames to run.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final box =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: tester.view.devicePixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> scroll(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
    await settle(tester);
  }

  Future<void> pickRole(WidgetTester tester, String label) async {
    await tester.tap(find.textContaining('Rôle :'));
    await settle(tester);
    await tester.tap(find.text(label));
    await settle(tester);
  }

  /// Scrolls the métré without a drag: a drag over the plan draws a room.
  Future<void> scrollMetre(
    WidgetTester tester,
    double dy, {
    bool absolute = false,
  }) async {
    final list = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(MetreScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final p = list.position;
    p.jumpTo(
      (absolute ? dy : p.pixels + dy).clamp(0, p.maxScrollExtent).toDouble(),
    );
    await settle(tester);
  }

  Future<ImmoModuleSession> pumpModule(
    WidgetTester tester, {
    required Color accent,
    required String label,
    required Widget navigator,
  }) async {
    final session = ImmoModuleSession(
      apiClient: ImmoApiClient(
        baseUrl: 'http://demo',
        httpClient: MockClient(_demoBackend),
      ),
    );
    await tester.runAsync(session.bootstrap);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Urbanist'),
          home: ImmoModuleSessionScope(
            session: session,
            child: ImmoModuleShell(
              primaryColor: accent,
              moduleLabel: label,
              child: ImmoRentalTheme(accent: accent, child: navigator),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    await settle(tester);
    return session;
  }

  testWidgets('Collection screenshots', skip: outDir == null, (tester) async {
    await phone(tester);
    await withShadows(() async {
      await pumpModule(
        tester,
        accent: ImmoBrand.collectionPrimary,
        label: 'Mr Immo Collection',
        navigator: const CollectionNavigator(),
      );
      await shot(tester, '01-collection-accueil');

      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await settle(tester);
      await shot(tester, '02-collection-loyers');

      await tester.tap(find.text('Awa Koné').first);
      await settle(tester);
      await tester.tap(find.text('Mobile money'));
      await settle(tester);
      await shot(tester, '03-collection-encaisser');
      await tester.tapAt(const Offset(195, 120));
      await settle(tester);

      await scroll(tester, 700);
      await shot(tester, '04-collection-loyers-suite');

      await tester.tap(find.byIcon(Icons.apartment_outlined));
      await settle(tester);
      await shot(tester, '05-collection-biens');
    });
  });

  _superviseurScreenshots(
    phone,
    withShadows,
    (t, {required accent, required label, required navigator}) =>
        pumpModule(t, accent: accent, label: label, navigator: navigator),
    settle,
    shot,
    outDir == null,
  );

  testWidgets('Construction screenshots', skip: outDir == null, (tester) async {
    await phone(tester);
    await withShadows(() async {
      await pumpModule(
        tester,
        accent: ImmoBrand.constructionPrimary,
        label: 'Mr Immo Construction',
        navigator: const ConstructionMainNavigation(),
      );
      await pickRole(tester, 'Chef de chantier');
      await settle(tester);
      await shot(tester, '06-construction-accueil');

      await tester.tap(find.byIcon(Icons.foundation_outlined));
      await settle(tester);
      await shot(tester, '07-construction-chantiers');

      await tester.tap(find.text('Villa Bingerville'));
      await settle(tester);
      await shot(tester, '08-construction-fiche-chantier');

      // A delivered demande, checked on site
      await tester.tap(find.text('À réceptionner'));
      await settle(tester);
      await shot(tester, '08b-chef-reception');
      final missing = find.text('Il manque quelque chose');
      await tester.ensureVisible(missing);
      await tester.tap(missing);
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, '228'), '208');
      await settle(tester);
      await tester.ensureVisible(find.text('Confirmer la réception'));
      await settle(tester);
      await shot(tester, '08c-chef-reception-manque');
      Navigator.of(tester.element(find.text('Confirmer la réception'))).pop();
      await settle(tester);

      await tester.tap(find.text('Villa Bingerville'));
      await settle(tester);
      await tester.ensureVisible(find.text('Métré & matériaux'));
      await settle(tester);
      await tester.tap(find.text('Métré & matériaux'));
      await settle(tester);
      await settle(tester);
      await shot(tester, '09-metre-plan');

      await scrollMetre(tester, 640);
      await shot(tester, '10-metre-plan-pieces');

      await scrollMetre(tester, 0, absolute: true);
      await tester.tap(find.text('Dimensions'));
      await settle(tester);
      await shot(tester, '11-metre-dimensions');
      await tester.tap(find.text('Plan'));
      await settle(tester);

      await scrollMetre(tester, 1700);
      await shot(tester, '12-metre-resultat');

      await scrollMetre(tester, 750);
      await shot(tester, '13-metre-phases');

      await scrollMetre(tester, 900);
      await shot(tester, '14-metre-hypotheses');

      await scrollMetre(tester, 1700, absolute: true);
      await tester.ensureVisible(find.text('Ciment', skipOffstage: false));
      await settle(tester);
      await tester.tap(find.text('Ciment'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Facultatif'),
        '5500',
      );
      await settle(tester);
      await shot(tester, '15-metre-modifier-ciment');
    });
  });
}

void _superviseurScreenshots(
  Future<void> Function(WidgetTester) phone,
  Future<void> Function(Future<void> Function()) withShadows,
  Future<void> Function(
    WidgetTester, {
    required Color accent,
    required String label,
    required Widget navigator,
  })
  pumpModule,
  Future<void> Function(WidgetTester) settle,
  Future<void> Function(WidgetTester, String) shot,
  bool skip,
) {
  testWidgets('Superviseur screenshots', skip: skip, (tester) async {
    await phone(tester);
    await withShadows(() async {
      await pumpModule(
        tester,
        accent: ImmoBrand.constructionPrimary,
        label: 'Mr Immo Construction',
        navigator: const ConstructionMainNavigation(),
      );
      await tester.tap(find.textContaining('Rôle :'));
      await settle(tester);
      await shot(tester, '16-role');
      await tester.tap(find.text('Superviseur'));
      await settle(tester);
      await shot(tester, '17-superviseur-accueil');

      await tester.tap(find.byIcon(Icons.fact_check_outlined).last);
      await settle(tester);
      await shot(tester, '18-superviseur-demandes');

      await tester.tap(find.text('Villa Bingerville').first);
      await settle(tester);
      await shot(tester, '19-superviseur-demande');

      await tester.tap(find.text('Refuser'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Ex. Quantité de fer trop élevée'),
        'Le sable est déjà sur le chantier',
      );
      await settle(tester);
      await shot(tester, '20-superviseur-refus');
    });
  });

  testWidgets('Fournisseur screenshots', skip: skip, (tester) async {
    await phone(tester);
    await withShadows(() async {
      await pumpModule(
        tester,
        accent: ImmoBrand.constructionPrimary,
        label: 'Mr Immo Construction',
        navigator: const ConstructionMainNavigation(),
      );
      await settle(tester);
      await shot(tester, '24-fournisseur-accueil');

      await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
      await settle(tester);
      await shot(tester, '25-fournisseur-commandes');

      await tester.tap(find.text('Villa Bingerville'));
      await settle(tester);
      await shot(tester, '26-fournisseur-mise-en-route');
      Navigator.of(tester.element(find.text('Mettre en route'))).pop();
      await settle(tester);

      await tester.tap(find.text('Résidence Riviera'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Ex. Déchargé au portail, reçu par le gardien',
        ),
        'Reçu par le chef de chantier',
      );
      await settle(tester);
      await shot(tester, '27-fournisseur-livraison');
    });
  });

  testWidgets('Moyens généraux screenshots', skip: skip, (tester) async {
    await phone(tester);
    await withShadows(() async {
      await pumpModule(
        tester,
        accent: ImmoBrand.constructionPrimary,
        label: 'Mr Immo Construction',
        navigator: const ConstructionMainNavigation(),
      );
      await tester.tap(find.textContaining('Rôle :'));
      await settle(tester);
      await tester.tap(find.text('Moyens généraux'));
      await settle(tester);
      await shot(tester, '21-moyens-generaux-accueil');

      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).last);
      await settle(tester);
      await shot(tester, '22-moyens-generaux-achats');

      await tester.tap(find.text('Duplex Cocody').first);
      await settle(tester);
      await tester.ensureVisible(find.text('Sablière de Bingerville'));
      await tester.tap(find.text('Matériaux Plus CI'));
      await settle(tester);
      await shot(tester, '23-moyens-generaux-commande');
    });
  });
}

class _DemoHost implements ImmoHostAuth {
  @override
  Future<bool> isRegistered() async => true;
  @override
  Future<bool> isSessionActive() async => true;
  @override
  Future<String?> displayName() async => 'Ibrahim';
  @override
  Future<String?> getPhone() async => '0707070707';
  @override
  Future<String?> getPinForPhone(String phone) async => null;
  @override
  Future<String?> authToken() async => 'demo';
  @override
  Future<void> setAuthToken(String? token) async {}
  @override
  Future<String?> immoUserId() async => 'u1';
  @override
  Future<void> setImmoUserId(String? userId) async {}
  @override
  Future<String?> monPeyaAccessToken() async => null;
}

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(File(path).readAsBytesSync());
  final urbanist = FontLoader('Urbanist');
  for (final f in Directory(
    '../../app/assets/fonts/urbanist',
  ).listSync().whereType<File>()) {
    if (f.path.endsWith('.ttf') && !f.path.contains('Italic')) {
      urbanist.addFont(bytes(f.path));
    }
  }
  await urbanist.load();
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  await (FontLoader(
    'MaterialIcons',
  )..addFont(bytes('$fonts/MaterialIcons-Regular.otf'))).load();
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(bytes('$fonts/Roboto-$w.ttf'));
  }
  await roboto.load();
}

// ── Sample backend ─────────────────────────────────────────────────────────

Future<http.Response> _demoBackend(http.Request req) async {
  final path = req.url.path;
  final now = DateTime.now();
  String day(int offset) => now.add(Duration(days: offset)).toIso8601String();
  http.Response ok(Map<String, dynamic> body) => http.Response(
    jsonEncode({
      'hasError': false,
      'status': {'code': '800', 'message': 'ok'},
      ...body,
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Map<String, dynamic> pay(
    String id,
    String tenant,
    String tId,
    String bien,
    String bId,
    num amount,
    int dueIn, {
    int? paidAgo,
    String? method,
  }) => {
    'paiementsId': id,
    'montant': amount,
    'dateEcheance': day(dueIn),
    'datePaiement': paidAgo == null ? null : day(-paidAgo),
    'statut': paidAgo == null ? 'pending' : 'paid',
    'methodePaiement': method,
    'locatairesId': tId,
    'locataireNom': tenant,
    'biensId': bId,
    'bienNom': bien,
  };

  if (path == '/api/paiements/collection/u1') {
    return ok({
      'items': [
        pay('p1', 'Awa Koné', 't1', 'Résidence Akwaba', 'b1', 250000, -18),
        pay(
          'p2',
          'Jean-Marc Kouassi',
          't3',
          'Immeuble Plateau',
          'b2',
          450000,
          -6,
        ),
        pay('p3', 'Awa Koné', 't1', 'Résidence Akwaba', 'b1', 250000, 12),
        pay('p4', 'Mariam Traoré', 't2', 'Résidence Akwaba', 'b1', 180000, 9),
        pay(
          'p5',
          'Jean-Marc Kouassi',
          't3',
          'Immeuble Plateau',
          'b2',
          450000,
          24,
        ),
        pay(
          'p6',
          'Mariam Traoré',
          't2',
          'Résidence Akwaba',
          'b1',
          180000,
          -21,
          paidAgo: 3,
          method: 'Peya Pay',
        ),
        pay(
          'p7',
          'Awa Koné',
          't1',
          'Résidence Akwaba',
          'b1',
          250000,
          -48,
          paidAgo: 45,
          method: 'Espèces',
        ),
        pay(
          'p8',
          'Jean-Marc Kouassi',
          't3',
          'Immeuble Plateau',
          'b2',
          450000,
          -36,
          paidAgo: 10,
          method: 'Virement',
        ),
      ],
    });
  }
  if (path == '/api/paiements/collection/u1/tenants') {
    Map<String, dynamic> t(
      String id,
      String nom,
      String bId,
      String bien,
      String adr,
      num loyer,
      int sched,
    ) => {
      'locatairesId': id,
      'nom': nom,
      'biensId': bId,
      'bienNom': bien,
      'bienAdresse': adr,
      'montantLoyer': loyer,
      'frequencePaiement': 'monthly',
      'dateDebutBail': day(-120),
      'dateFinBail': day(245),
      'echeancesGenerees': sched,
    };
    return ok({
      'items': [
        t(
          't1',
          'Awa Koné',
          'b1',
          'Résidence Akwaba',
          'Cocody Angré, Abidjan',
          250000,
          12,
        ),
        t(
          't2',
          'Mariam Traoré',
          'b1',
          'Résidence Akwaba',
          'Cocody Angré, Abidjan',
          180000,
          12,
        ),
        t(
          't3',
          'Jean-Marc Kouassi',
          'b2',
          'Immeuble Plateau',
          'Plateau, Abidjan',
          450000,
          12,
        ),
        t(
          't4',
          'Koffi Yao',
          'b2',
          'Immeuble Plateau',
          'Plateau, Abidjan',
          300000,
          0,
        ),
      ],
    });
  }
  if (path == '/api/chantiers/user/u1') {
    String d(int offset) => day(offset).substring(0, 10);
    return ok({
      'items': [
        {
          'chantiersId': 's1',
          'nom': 'Villa Bingerville',
          'statut': 'en_cours',
          'ville': 'Bingerville',
          'adresse': 'Route de Bingerville',
          'surfaceM2': 380,
          'budgetAlloue': 120000000,
          'dateDebut': d(-90),
          'dateFinPrevue': d(240),
        },
        {
          'chantiersId': 's2',
          'nom': 'Résidence Riviera',
          'statut': 'planifié',
          'ville': 'Abidjan',
          'adresse': 'Riviera 3, Cocody',
          'surfaceM2': 1200,
          'budgetAlloue': 450000000,
          'dateDebut': d(-30),
          'dateFinPrevue': d(420),
        },
        {
          'chantiersId': 's3',
          'nom': 'Duplex Cocody',
          'statut': 'terminé',
          'ville': 'Abidjan',
          'adresse': 'Cocody Danga',
          'surfaceM2': 260,
          'biensId': 'b9',
          'dateFinReelle': d(-40),
          'dateOuvertureLocation': day(-40),
        },
      ],
    });
  }
  if (path == '/api/demandes/entreprise/u1') {
    Map<String, dynamic> d(
      String id,
      String chantier,
      String etat,
      num budget,
      int daysAgo, {
      String? motif,
    }) => {
      'demandesId': id,
      'titre': 'Matériaux — $chantier',
      'description': motif == null ? null : 'Motif du refus : $motif',
      'justification':
          'Quantités calculées depuis le métré du ${day(-daysAgo - 1).substring(8, 10)}/${day(-daysAgo - 1).substring(5, 7)}/${day(-daysAgo - 1).substring(0, 4)}',
      'budgetEstime': budget,
      'urgence': 'NORMAL',
      'etat': etat,
      'createdAt': day(-daysAgo),
      'chantiersId': const {
        'Villa Bingerville': 's1',
        'Résidence Riviera': 's2',
        'Duplex Cocody': 's3',
      }[chantier],
      'chantierNom': chantier,
      'lignes': [
        {
          'libelle': 'Ciment',
          'quantite': 228,
          'unite': 'sac',
          'montant': 1254000,
        },
        {'libelle': 'Sable', 'quantite': 21, 'unite': 'm³', 'montant': 420000},
        {
          'libelle': 'Gravier',
          'quantite': 21,
          'unite': 'm³',
          'montant': 525000,
        },
        {
          'libelle': 'Agglos 15 × 20 × 40',
          'quantite': 2012,
          'unite': 'unité',
          'montant': 804800,
        },
        {
          'libelle': 'Fer à béton HA10',
          'quantite': 110,
          'unite': 'barre',
          'montant': 495000,
        },
      ],
    };
    return ok({
      'items': [
        d('d1', 'Villa Bingerville', 'en attente', 3498800, 1),
        d('d2', 'Résidence Riviera', 'en attente', 8500000, 2),
        d('d3', 'Duplex Cocody', 'validé_superviseur', 2150000, 9),
        d(
          'd4',
          'Résidence Riviera',
          'refusé',
          1200000,
          14,
          motif: 'Quantité de fer trop élevée',
        ),
        {
          ...d('d5', 'Villa Bingerville', 'envoyé_fournisseur', 1840000, 20),
          'fournisseurNom': 'Matériaux Plus CI',
          'numeroCommande': 'CMD-261003-5E1F2A-1',
          'dateCommande': day(-19),
        },
        {
          ...d('d6', 'Duplex Cocody', 'terminé', 2600000, 35),
          'fournisseurNom': 'Quincaillerie Adjamé',
          'numeroCommande': 'CMD-260918-77C0D1-1',
          'dateCommande': day(-34),
          'dateLivraison': day(-31),
          'dateReception': day(-31),
        },
        {
          ...d('d7', 'Villa Bingerville', 'livré_chantier', 2274000, 8),
          'dateValidation': day(-7),
          'fournisseurNom': 'Matériaux Plus CI',
          'numeroCommande': 'CMD-261016-9B3C4D-1',
          'dateCommande': day(-6),
          'dateExpedition': day(-2),
          'dateLivraisonPrevue': day(-1).substring(0, 10),
          'dateLivraison': day(-1),
          'lignes': [
            {
              'libelle': 'Ciment',
              'quantite': 228,
              'unite': 'sac',
              'montant': 1254000,
              'commandesId': 'l1',
              'quantiteLivree': 228,
            },
            {
              'libelle': 'Fer à béton HA10',
              'quantite': 110,
              'unite': 'barre',
              'montant': 495000,
              'commandesId': 'l2',
              'quantiteLivree': 110,
            },
            {
              'libelle': 'Gravier',
              'quantite': 21,
              'unite': 'm³',
              'montant': 525000,
              'commandesId': 'l3',
              'quantiteLivree': 21,
            },
          ],
        },
      ],
    });
  }
  if (path == '/api/demandes/fournisseur/u1/commandes') {
    Map<String, dynamic> o(
      String id,
      String chantier,
      String adresse,
      String etat,
      int daysAgo,
      num total, {
      int? deliveredAgo,
    }) => {
      'demandesId': id,
      'numeroCommande':
          'CMD-${day(-daysAgo).substring(2, 10).replaceAll('-', '')}-${id.toUpperCase()}7A2F-1',
      'dateCommande': day(-daysAgo),
      'chantierNom': chantier,
      'instructionLivraison': 'Livraison au chantier « $chantier » — $adresse',
      'transporteur': 'Fournisseur',
      'etat': etat,
      'dateLivraison': deliveredAgo == null ? null : day(-deliveredAgo),
      'montantTotal': total,
      'lignes': [
        {
          'libelle': 'Ciment',
          'quantiteCommandee': 228,
          'quantiteLivree': 0,
          'unite': 'sac',
          'montant': 1254000,
        },
        {
          'libelle': 'Fer à béton HA10',
          'quantiteCommandee': 110,
          'quantiteLivree': 0,
          'unite': 'barre',
          'montant': 495000,
        },
        {
          'libelle': 'Gravier',
          'quantiteCommandee': 21,
          'quantiteLivree': 0,
          'unite': 'm³',
          'montant': 525000,
        },
      ],
    };
    return ok({
      'items': [
        o(
          'c1',
          'Villa Bingerville',
          'Route de Bingerville',
          'envoyé_fournisseur',
          1,
          2274000,
        ),
        {
          ...o(
            'c2',
            'Résidence Riviera',
            'Riviera 3, Cocody, Abidjan',
            'en_livraison',
            3,
            2274000,
          ),
          'dateExpedition': day(0),
          'dateLivraisonPrevue': day(1).substring(0, 10),
        },
        o(
          'c3',
          'Duplex Cocody',
          'Cocody Danga, Abidjan',
          'terminé',
          12,
          2274000,
          deliveredAgo: 9,
        ),
      ],
    });
  }
  if (path == '/api/demandes/fournisseurs') {
    return ok({
      'items': [
        {
          'fournisseursId': 'f2',
          'nom': 'Matériaux Plus CI',
          'specialites': 'Ciment, fer, agrégats',
          'evaluationQualite': 4,
        },
        {
          'fournisseursId': 'f1',
          'nom': 'Quincaillerie Adjamé',
          'specialites': 'Fer, outillage',
          'evaluationQualite': 3,
        },
        {
          'fournisseursId': 'f3',
          'nom': 'Sablière de Bingerville',
          'specialites': 'Sable, gravier',
          'evaluationQualite': 4,
        },
      ],
    });
  }
  if (path == '/api/chantiers/s1/metre') {
    return ok({'item': _bungalowMetre(now)});
  }
  if (path.endsWith('/metre')) return ok({});
  return http.Response('not found', 404);
}

/// What the backend returns for the 12 × 10 m bungalow (see MetreCalculatorTest).
Map<String, dynamic> _bungalowMetre(DateTime now) {
  Map<String, dynamic> l(String code, String label, num q, String unit) => {
    'code': code,
    'libelle': label,
    'quantite': q,
    'unite': unit,
  };
  return {
    'chantiersId': 's1',
    'updatedAt': now.toIso8601String(),
    'donnees': {
      'longueur': 12,
      'largeur': 10,
      'niveaux': 1,
      'hauteurMur': 2.8,
      'pieces': [
        {'nom': 'Salon', 'longueur': 6, 'largeur': 10},
        {'nom': 'Chambre 1', 'longueur': 6, 'largeur': 5},
        {'nom': 'Chambre 2', 'longueur': 6, 'largeur': 5},
      ],
      'portes': {'nombre': 4, 'largeur': 0.9, 'hauteur': 2.1},
      'fenetres': {'nombre': 5, 'largeur': 1.2, 'hauteur': 1.2},
      'epaisseurAgglo': 15,
      'toitureTerrasse': false,
      'perte': 0.05,
      'longueurMursExterieurs': 44,
      'surfaceEmprise': 120,
      'plan': {
        'cellule': 0.5,
        'pieces': [
          {'nom': 'Salon', 'x': 4, 'y': 4, 'l': 12, 'h': 20},
          {'nom': 'Chambre 1', 'x': 16, 'y': 4, 'l': 12, 'h': 10},
          {'nom': 'Chambre 2', 'x': 16, 'y': 14, 'l': 12, 'h': 10},
        ],
        'ouvertures': [
          {'type': 'porte', 'x': 9, 'y': 24, 'horizontal': true},
          {'type': 'porte', 'x': 7, 'y': 4, 'horizontal': true},
          {'type': 'porte', 'x': 16, 'y': 8, 'horizontal': false},
          {'type': 'porte', 'x': 16, 'y': 18, 'horizontal': false},
          {'type': 'fenetre', 'x': 4, 'y': 10, 'horizontal': false},
          {'type': 'fenetre', 'x': 4, 'y': 16, 'horizontal': false},
          {'type': 'fenetre', 'x': 21, 'y': 4, 'horizontal': true},
          {'type': 'fenetre', 'x': 28, 'y': 8, 'horizontal': false},
          {'type': 'fenetre', 'x': 28, 'y': 19, 'horizontal': false},
        ],
      },
    },
    'resultat': {
      'surfaces': {
        'emprise': 120,
        'longueurMursExterieurs': 44,
        'longueurMursInterieurs': 16,
        'surfaceMursNette': 153.24,
        'surfaceOuvertures': 14.76,
        'surfaceSol': 120,
        'volumeBeton': 24.23,
      },
      'phases': [
        {
          'code': 'FONDATIONS',
          'libelle': 'Fondations',
          'lignes': [
            l('CIMENT', 'Ciment', 67.5, 'sac'),
            l('SABLE', 'Sable', 4.81, 'm³'),
            l('GRAVIER', 'Gravier', 7.81, 'm³'),
            l('AGGLO_20', 'Agglos 20 × 20 × 40', 472.5, 'unité'),
            l('FER_HA10', 'Fer à béton HA10', 68.11, 'barre'),
          ],
        },
        {
          'code': 'ELEVATION',
          'libelle': 'Élévation des murs',
          'lignes': [
            l('CIMENT', 'Ciment', 38.94, 'sac'),
            l('SABLE', 'Sable', 4.13, 'm³'),
            l('GRAVIER', 'Gravier', 2.46, 'm³'),
            l('AGGLO_15', 'Agglos 15 × 20 × 40', 2011.28, 'unité'),
            l('FER_HA10', 'Fer à béton HA10', 41.63, 'barre'),
          ],
        },
        {
          'code': 'DALLES',
          'libelle': 'Dallage',
          'lignes': [
            l('CIMENT', 'Ciment', 75.6, 'sac'),
            l('SABLE', 'Sable', 5.04, 'm³'),
            l('GRAVIER', 'Gravier', 10.08, 'm³'),
          ],
        },
        {
          'code': 'ENDUITS',
          'libelle': 'Enduits (deux faces)',
          'lignes': [
            l('CIMENT', 'Ciment', 45.05, 'sac'),
            l('SABLE', 'Sable', 6.44, 'm³'),
          ],
        },
        {
          'code': 'FINITIONS',
          'libelle': 'Carrelage et peinture',
          'lignes': [
            l('CARRELAGE', 'Carrelage', 126, 'm²'),
            l('PEINTURE', 'Peinture', 89.56, 'L'),
          ],
        },
      ],
      'totaux': [
        l('CIMENT', 'Ciment', 228, 'sac'),
        l('SABLE', 'Sable', 21, 'm³'),
        l('GRAVIER', 'Gravier', 21, 'm³'),
        l('AGGLO_15', 'Agglos 15 × 20 × 40', 2012, 'unité'),
        l('AGGLO_20', 'Agglos 20 × 20 × 40', 473, 'unité'),
        l('FER_HA10', 'Fer à béton HA10', 110, 'barre'),
        l('CARRELAGE', 'Carrelage', 126, 'm²'),
        l('PEINTURE', 'Peinture', 90, 'L'),
      ],
      'hypotheses': [
        'Même plan à chaque niveau, portes et fenêtres comprises.',
        'Agglos 40 × 20 cm : 12,5 par m² de mur, mortier de pose dosé à 300 kg/m³.',
        'Fondations : semelles filantes 40 × 25 cm sous tous les murs, soubassement de 60 cm en agglos de 20.',
        'Poteaux tous les 3,5 m, chaînage en tête de chaque niveau.',
        'Béton armé dosé à 350 kg/m³ : 0,4 m³ de sable et 0,8 m³ de gravier par m³.',
        'Fer : 100 kg/m³ (poteaux, chaînages), 80 kg/m³ (dalles), 50 kg/m³ (semelles), en barres HA10 de 12 m (7,4 kg).',
        'Enduit de 2 cm sur les deux faces des murs, dosé à 350 kg/m³.',
        'Peinture : 2 couches, 10 m² par litre.',
        'Pertes ajoutées : 5 %.',
      ],
    },
  };
}
