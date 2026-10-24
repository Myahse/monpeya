import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immo/immo.dart';

/// A single-role app (here the superviseur's) against a fake backend: code client + PIN
/// sign-in, wrong-role refusal, the role's home without picker, sign-out, restored session.
void main() {
  http.Response json(Map<String, dynamic> body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  http.Response ok(Map<String, dynamic> body) =>
      json({'hasError': false, 'status': {'code': '800', 'message': 'ok'}, ...body});

  Map<String, dynamic> account(String id, String level, String prenoms, String nom) => {
        'message': 'Authentication successful',
        'token': 'jwt-$id',
        'utilisateursId': id,
        'niveauAcces': level,
        'prenoms': prenoms,
        'nom': nom,
        'email': '$id@demo.ci',
      };

  late List<String> loggedOut;
  late bool tokenValid;

  MockClient backend() => MockClient((req) async {
        final path = req.url.path;
        if (path == '/api/auth/pin-login') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          if (body['pin'] == '1234') {
            if (body['codeClient'] == '0700000203') return json(account('sup', 'SUPERVISEUR', 'Aya', 'Kouadio'));
            if (body['codeClient'] == '0700000202') return json(account('chef', 'CHEF_CHANTIER', 'Sekou', 'Coulibaly'));
          }
          return json({'error': 'invalid_credentials', 'message': 'Code client ou code PIN incorrect.'}, 401);
        }
        if (path == '/api/auth/logout') {
          loggedOut.add(req.headers['Authorization'] ?? '');
          return json({'message': 'Logout successful'});
        }
        if (path == '/api/auth/validate') {
          return tokenValid ? json({'valid': true}) : json({'valid': false, 'error': 'Invalid token'}, 401);
        }
        if (path == '/api/chantiers/user/sup') return ok({'items': []});
        if (path == '/api/chantiers/role/sup') return ok({'item': 'SUPERVISEUR'});
        if (path == '/api/demandes/entreprise/sup') {
          return ok({
            'items': [
              {
                'demandesId': 'd1',
                'titre': 'Matériaux — Villa Bingerville',
                'etat': 'en attente',
                'chantierNom': 'Villa Bingerville',
                'lignes': [],
              },
            ],
          });
        }
        return http.Response('not found', 404);
      });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  setUp(() {
    loggedOut = [];
    tokenValid = true;
  });

  tearDown(() {
    ImmoHostBridge.auth = null;
    ImmoHostBridge.onExitModule = null;
    ImmoHostBridge.exitLabel = 'Retour à Mon Peya';
    ImmoEnvRegistry.reset();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ConstructionRoleApp(
      appId: 'test_superviseur',
      role: ConstructionRole.superviseur,
      httpClient: backend(),
    ));
    await settle(tester);
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.widgetWithText(TextField, 'Ex. 07 00 00 02 03'), code);
    await tester.tap(find.text('Continuer'));
    await settle(tester);
  }

  /// Taps the digits on the shuffled keypad; the 4th sends the PIN.
  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await settle(tester);
  }

  testWidgets('signs in with the role’s code client and PIN only, then signs out', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await open(tester);
    expect(find.text('Superviseur'), findsOneWidget);
    expect(find.text('Code client'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await settle(tester);
    expect(find.text('Saisissez votre code client.'), findsOneWidget);

    await enterCode(tester, '0700000203');
    expect(find.text('Entrez votre code PIN'), findsOneWidget);
    expect(find.text('Code client 0700000203'), findsOneWidget);

    await typePin(tester, '0000');
    expect(find.text('Code client ou code PIN incorrect.'), findsOneWidget);
    expect(find.text('•'), findsNothing); // cleared for another try

    // A chef de chantier's account does not open the superviseur's app, and its token is dropped
    await tester.tap(find.text('Changer'));
    await settle(tester);
    await enterCode(tester, '0700000202');
    await typePin(tester, '1234');
    expect(
      find.text('Ce compte n’est pas un compte superviseur. Utilisez l’application de votre rôle.'),
      findsOneWidget,
    );
    expect(loggedOut, ['Bearer jwt-chef']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);

    await tester.tap(find.text('Changer'));
    await settle(tester);
    await enterCode(tester, '0700000203');
    await typePin(tester, '1234');
    expect(find.text('Bonjour, Aya Kouadio'), findsOneWidget);
    expect(find.text('Les demandes des chantiers à valider'), findsOneWidget);
    expect(find.textContaining('Rôle :'), findsNothing); // locked: no role picker
    expect(find.text('Demandes'), findsWidgets); // the superviseur's work tab (and its home action)
    expect(prefs.getString('immo_pro.test_superviseur.userId'), 'sup');

    // Profile (code client under the name) → Se déconnecter → confirm → back on the PIN
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await settle(tester);
    expect(find.text('0700000203'), findsOneWidget);
    await tester.tap(find.text('Se déconnecter'));
    await settle(tester);
    expect(find.text('Se déconnecter ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await settle(tester);
    expect(find.text('Entrez votre code PIN'), findsOneWidget);
    expect(find.text('Code client 0700000203'), findsOneWidget);
    expect(loggedOut.last, 'Bearer jwt-sup');
    expect(prefs.getKeys(), {'immo_pro.test_superviseur.codeClient'});
  });

  testWidgets('reopens on the role’s home while the token is valid', (tester) async {
    SharedPreferences.setMockInitialValues({
      'immo_pro.test_superviseur.token': 'jwt-sup',
      'immo_pro.test_superviseur.userId': 'sup',
      'immo_pro.test_superviseur.name': 'Aya Kouadio',
    });
    await open(tester);
    expect(find.text('Bonjour, Aya Kouadio'), findsOneWidget);
  });

  testWidgets('asks to sign in again once the token is refused', (tester) async {
    tokenValid = false;
    SharedPreferences.setMockInitialValues({
      'immo_pro.test_superviseur.token': 'jwt-old',
      'immo_pro.test_superviseur.userId': 'sup',
      'immo_pro.test_superviseur.codeClient': '0700000203',
    });
    await open(tester);
    expect(find.text('Entrez votre code PIN'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getKeys(), {'immo_pro.test_superviseur.codeClient'});
  });
}
