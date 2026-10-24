import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/shared/auth/services/immo_auth.service.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

/// Which Mr Immo user a signed-in Mon Peya session is linked to.
void main() {
  const owner = 'daa6f512-a510-4d0f-ade0-85d95967cc77';

  tearDown(() => ImmoHostBridge.auth = null);

  test('A Mon Peya id stored by an older version is dropped, and the user found by phone again', () async {
    final host = _Host(storedId: '5');
    ImmoHostBridge.auth = host;
    final asked = <String>[];
    final sessions = <String?>[];
    // A fresh client, like the app's background sync makes: it sends the host's session unasked
    final client = ImmoApiClient(
      baseUrl: 'http://test',
      httpClient: MockClient((req) async {
        asked.add(req.url.path);
        sessions.add(req.headers['X-MonPeya-Token']);
        final phone = (jsonDecode(req.body)['data'] as Map)['numeroTelephone'];
        final items = phone == '+2250700000102' ? [{'utilisateursId': owner}] : [];
        return http.Response(jsonEncode({'hasError': false, 'items': items}), 200,
            headers: {'content-type': 'application/json'});
      }),
    );

    final result = await ImmoAuthService(client: client).ensureSession(apiClient: client);

    expect(result.ok, isTrue);
    expect(result.userId, owner);
    expect(host.storedId, owner);
    expect(asked, contains('/api/utilisateurs/getByCriteria'));
    // Mr Immo answers the user lookup only to a signed-in caller
    expect(sessions, everyElement('mp-session'));
  });

  test('Without a Mon Peya host a client sends no session', () async {
    String? sent = 'unset';
    final client = ImmoApiClient(
      baseUrl: 'http://test',
      httpClient: MockClient((req) async {
        sent = req.headers['X-MonPeya-Token'];
        return http.Response('{"hasError":false}', 200, headers: {'content-type': 'application/json'});
      }),
    );

    await client.postJson('/api/paiements/generate/t1', body: {});

    expect(sent, isNull);
  });

  test('A stored Mr Immo id is used as it is', () async {
    ImmoHostBridge.auth = _Host(storedId: owner);
    final client = ImmoApiClient(
      baseUrl: 'http://test',
      httpClient: MockClient((req) async => fail('no request expected: ${req.url}')),
    );

    final result = await ImmoAuthService(client: client).ensureSession(apiClient: client);

    expect(result.userId, owner);
  });
}

/// The Mon Peya host after the owner signed in with their phone.
class _Host implements ImmoHostAuth {
  _Host({this.storedId});

  String? storedId;

  @override
  Future<bool> isRegistered() async => true;
  @override
  Future<bool> isSessionActive() async => true;
  @override
  Future<String?> displayName() async => 'Traoré Agent démo';
  @override
  Future<String?> getPhone() async => '+2250700000102';
  @override
  Future<String?> getPinForPhone(String phone) async => null;
  @override
  Future<String?> authToken() async => 'mp-session';
  @override
  Future<void> setAuthToken(String? token) async {}
  @override
  Future<String?> immoUserId() async => storedId;
  @override
  Future<void> setImmoUserId(String? userId) async => storedId = userId;
  @override
  Future<String?> monPeyaAccessToken() async => 'mp-session';
}
