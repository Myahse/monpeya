import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/navigation/construction_main.navigation.dart';
import 'package:immo/src/features/construction/role_app/role_login.screen.dart';
import 'package:immo/src/shared/auth/immo_module.session.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/auth/services/immo_pro_auth.service.dart';
import 'package:immo/src/shared/config/immo_env.registry.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/shared/widgets/immo_module_shell.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// One Mr Immo Construction role as its own app (chef de chantier, superviseur…):
/// code client + PIN sign-in (as in Mon Peya), then the Construction tabs of that role only.
///
/// The API comes from `--dart-define=IMMO_API_URL=http://<host>:8082`
/// (default: the Android emulator's host machine).
class ConstructionRoleApp extends StatefulWidget {
  const ConstructionRoleApp({
    super.key,
    required this.appId,
    required this.role,
    this.httpClient,
  });

  /// Keeps each app's session apart (`immo_superviseur`…).
  final String appId;
  final ConstructionRole role;

  /// Tests only: replaces the network.
  final http.Client? httpClient;

  @override
  State<ConstructionRoleApp> createState() => _ConstructionRoleAppState();
}

class _ConstructionRoleAppState extends State<ConstructionRoleApp> {
  static const _apiUrl = String.fromEnvironment('IMMO_API_URL', defaultValue: 'http://10.0.2.2:8082');
  static const _accent = ImmoBrand.constructionPrimary;

  late final ImmoProAuth _auth;
  late final ImmoModuleSession _session;

  /// Opens the sign-in on the PIN, as Mon Peya keeps the phone.
  String? _lastCodeClient;

  @override
  void initState() {
    super.initState();
    if (ImmoEnvRegistry.baseUrl == null) ImmoEnvRegistry.apply(baseUrl: _apiUrl);
    _auth = ImmoProAuth(appId: widget.appId, client: ImmoApiClient(httpClient: widget.httpClient));
    _session = ImmoModuleSession(apiClient: ImmoApiClient(httpClient: widget.httpClient));
    ImmoHostBridge.auth = _auth;
    ImmoHostBridge.onExitModule = _signOut;
    ImmoHostBridge.exitLabel = 'Se déconnecter';
    _start();
  }

  Future<void> _start() async {
    await _auth.restore();
    await _rememberCodeClient();
    await _session.bootstrap();
  }

  Future<void> _rememberCodeClient() async {
    final last = await _auth.lastCodeClient();
    if (mounted) setState(() => _lastCodeClient = last);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<String?> _signIn(String codeClient, String pin) async {
    final error = await _auth.login(
      codeClient: codeClient,
      pin: pin,
      allows: (level) => ConstructionRole.fromAccessLevel(level) == widget.role,
      wrongRoleMessage: 'Ce compte n’est pas un compte ${widget.role.label.toLowerCase()}. '
          'Utilisez l’application de votre rôle.',
    );
    if (error == null) await _session.bootstrap();
    return error;
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await showImmoConfirm(
      context,
      title: 'Se déconnecter ?',
      message: 'Il faudra saisir à nouveau votre code PIN.',
      confirmLabel: 'Se déconnecter',
    );
    if (!ok) return;
    await _auth.logout();
    await _rememberCodeClient();
    _session.client.setAuthToken(null);
    await _session.bootstrap();
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
        useMaterial3: true,
        fontFamily: ImmoBrand.fontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: brightness),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immo ${widget.role.label}',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: ImmoModuleSessionScope(
        session: _session,
        child: ImmoModuleShell(
          primaryColor: _accent,
          moduleLabel: 'Mr Immo Construction',
          child: ImmoRentalTheme(
            accent: _accent,
            child: _RoleGate(role: widget.role, lastCodeClient: _lastCodeClient, onSignIn: _signIn),
          ),
        ),
      ),
    );
  }
}

/// Loading, then sign-in until a session exists, then the role's tabs.
class _RoleGate extends StatelessWidget {
  const _RoleGate({required this.role, required this.lastCodeClient, required this.onSignIn});

  final ConstructionRole role;
  final String? lastCodeClient;
  final Future<String?> Function(String codeClient, String pin) onSignIn;

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    if (!session.ready) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: ImmoBrand.rentalOf(context).primary)),
      );
    }
    if (!session.authenticated) {
      return RoleLoginScreen(role: role, initialCodeClient: lastCodeClient, onSubmit: onSignIn);
    }
    // A new store per account: nothing of the previous user lingers after a sign-out.
    return ConstructionMainNavigation(key: ValueKey(session.userId), lockedRole: role);
  }
}
