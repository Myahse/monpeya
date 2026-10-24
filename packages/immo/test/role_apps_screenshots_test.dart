import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo/immo.dart';

/// Phone-size screenshots of the four role apps signed in against a running backend
/// (demo accounts, `SEED_DEMO_DATA=true`, PIN 1234). Off by default; run with
/// ```
/// IMMO_SCREENSHOTS=<folder> IMMO_LIVE_API=http://localhost:8082 FLUTTER_ROOT=<flutter sdk> ///   flutter test test/role_apps_screenshots_test.dart
/// ```
void main() {
  final outDir = Platform.environment['IMMO_SCREENSHOTS'];
  final api = Platform.environment['IMMO_LIVE_API'];
  final skip = outDir == null || api == null;
  final boundary = GlobalKey();

  setUpAll(() async {
    if (skip) return;
    HttpOverrides.global = null; // talk to the real backend
    Directory(outDir).createSync(recursive: true);
    await _loadFonts();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    if (api != null) ImmoEnvRegistry.apply(baseUrl: api);
  });

  tearDown(() {
    ImmoHostBridge.auth = null;
    ImmoHostBridge.onExitModule = null;
    ImmoHostBridge.exitLabel = 'Retour à Mon Peya';
    ImmoEnvRegistry.reset();
  });

  /// Real requests answer in real time; then the fade-ins need frames.
  Future<void> settle(WidgetTester tester, {int rounds = 3}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  /// Real round trips chain several awaits, each needing a frame: wait until [finder] shows.
  Future<void> until(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await settle(tester, rounds: 1);
    }
    await settle(tester, rounds: 2); // let the fade-ins finish
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final box = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: tester.view.devicePixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> open(WidgetTester tester, String appId, ConstructionRole role) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: ConstructionRoleApp(appId: appId, role: role, httpClient: http.Client()),
    ));
    await settle(tester);
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    final change = find.text('Changer');
    if (change.evaluate().isNotEmpty) {
      await tester.tap(change);
      await settle(tester, rounds: 1);
    }
    await tester.enterText(find.widgetWithText(TextField, 'Ex. 07 00 00 02 03'), code);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.text('Continuer'));
    await settle(tester, rounds: 2);
  }

  /// The demo PIN on the shuffled keypad; the 4th digit sends it.
  Future<void> typePin(WidgetTester tester, String pin, {required Finder expecting}) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await until(tester, expecting);
  }

  Future<void> withShadows(Future<void> Function() body) async {
    debugDisableShadows = false;
    try {
      await body();
    } finally {
      debugDisableShadows = true;
    }
  }

  for (final (n, appId, role, code, tab) in [
    (1, 'immo_chantier', ConstructionRole.chefSite, '0700000202', 'Chantiers'),
    (2, 'immo_superviseur', ConstructionRole.superviseur, '0700000203', 'Demandes'),
    (3, 'immo_achats', ConstructionRole.moyensGeneraux, '0700000204', 'Achats'),
    (4, 'immo_fournisseur', ConstructionRole.supplier, '0700000301', 'Commandes'),
  ]) {
    testWidgets('$appId screenshots', skip: skip, (tester) async {
      await withShadows(() async {
        await open(tester, appId, role);
        expect(find.text('Continuer'), findsOneWidget);
        await shot(tester, 'app$n-$appId-1-code-client');

        if (role == ConstructionRole.superviseur) {
          // A wrong PIN, then another role's account: both refused
          await enterCode(tester, code);
          await tester.tap(find.text('1'));
          await tester.tap(find.text('2'));
          await tester.pump();
          await shot(tester, 'app$n-$appId-2-code-pin');
          final wrong = find.text('Code client ou code PIN incorrect.');
          await typePin(tester, '00', expecting: wrong);
          await shot(tester, 'app$n-$appId-2-pin-incorrect');

          final refused = find.textContaining('n’est pas un compte superviseur');
          await enterCode(tester, '0700000202');
          await typePin(tester, '1234', expecting: refused);
          expect(refused, findsOneWidget);
          await shot(tester, 'app$n-$appId-2-mauvais-role');
        }

        await enterCode(tester, code);
        await typePin(tester, '1234', expecting: find.textContaining('Bonjour'));
        expect(find.textContaining('Bonjour'), findsOneWidget);
        await settle(tester, rounds: 8); // the role's figures load after the greeting
        await shot(tester, 'app$n-$appId-3-accueil');

        await tester.tap(find.text(tab).last);
        await settle(tester, rounds: 4);
        await shot(tester, 'app$n-$appId-4-${tab.toLowerCase()}');

        await tester.tap(find.byIcon(Icons.person_outline_rounded));
        await settle(tester);
        expect(find.text('Se déconnecter'), findsOneWidget);
        await shot(tester, 'app$n-$appId-5-profil');

        // Unmount, then let the requests' timeout timers run out
        await tester.pumpWidget(const SizedBox());
        await settle(tester, rounds: 2);
        await tester.pump(const Duration(seconds: 20));
      });
    });
  }
}

/// Urbanist from the package itself (what the apps bundle), Material icons from the SDK.
Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async => ByteData.sublistView(File(path).readAsBytesSync());
  final urbanist = FontLoader('Urbanist');
  for (final f in Directory('lib/fonts/urbanist').listSync().whereType<File>()) {
    if (f.path.endsWith('.ttf')) urbanist.addFont(bytes(f.path));
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
