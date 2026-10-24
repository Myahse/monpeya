import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/messaging/screens/messages.screen.dart';
import 'package:immo/src/features/construction/screens/chef_site/screens/account.screen.dart' as chef;
import 'package:immo/src/features/construction/screens/chef_site/screens/chef_site_home.screen.dart';
import 'package:immo/src/features/construction/screens/chef_site/screens/payments.screen.dart' as chef_pay;
import 'package:immo/src/features/construction/models/construction.site.dart';
import 'package:immo/src/features/construction/screens/construction_work.screen.dart';
import 'package:immo/src/features/construction/screens/metre.screen.dart';
import 'package:immo/src/features/construction/screens/moyens_generaux/achats.screen.dart';
import 'package:immo/src/features/construction/screens/moyens_generaux/moyens_generaux_home.screen.dart';
import 'package:immo/src/features/construction/screens/superviseur/demandes.screen.dart';
import 'package:immo/src/features/construction/screens/superviseur/superviseur_home.screen.dart';
import 'package:immo/src/features/construction/screens/supplier/screens/account.screen.dart' as supplier;
import 'package:immo/src/features/construction/screens/supplier/screens/commandes.screen.dart';
import 'package:immo/src/features/construction/screens/supplier/screens/payments.screen.dart' as supplier_pay;
import 'package:immo/src/features/construction/screens/supplier/screens/supplier_home.screen.dart';
import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// Role-based tab navigator — same shell as Mr Immo Location.
class ConstructionMainNavigation extends StatefulWidget {
  const ConstructionMainNavigation({
    super.key,
    this.initialRole = ConstructionRole.supplier,
    this.initialTab = ConstructionTab.home,
    this.lockedRole,
  });

  final ConstructionRole initialRole;
  final ConstructionTab initialTab;

  /// A single-role app (e.g. the superviseur's): that role only, no role picker.
  final ConstructionRole? lockedRole;

  @override
  State<ConstructionMainNavigation> createState() =>
      _ConstructionMainNavigationState();
}

class _ConstructionMainNavigationState extends State<ConstructionMainNavigation> {
  late ConstructionRole _role = widget.lockedRole ?? widget.initialRole;
  late ConstructionTab _tab = widget.initialTab;
  ConstructionStore? _store;
  bool _requested = false;
  String? _requestedFor;

  /// Chantier whose métré is open full screen above the tabs.
  ConstructionSite? _metreSite;

  /// Once the user picks a role, the backend role no longer overrides it.
  bool _rolePicked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = ImmoModuleSessionScope.of(context);
    final store = _store ??= ConstructionStore(client: session.client)..addListener(_followAccessLevel);
    // The session bootstraps asynchronously; load once it knows who is signed in.
    if (!session.ready) return;
    final userId = session.authenticated ? session.userId : null;
    if (_requested && userId == _requestedFor) return;
    _requested = true;
    _requestedFor = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) store.load(userId);
    });
  }

  @override
  void dispose() {
    _store?.dispose();
    super.dispose();
  }

  void _openTab(ConstructionTab tab) => setState(() => _tab = tab);

  /// Null when the role is locked: the home header then shows no picker.
  ValueChanged<ConstructionRole>? get _onRoleChanged => widget.lockedRole == null ? _setRole : null;

  void _setRole(ConstructionRole role) => setState(() {
        _role = role;
        _rolePicked = true;
      });

  /// Opens on the user's own view (chef, superviseur, moyens généraux…) once the backend says who they are.
  void _followAccessLevel() {
    final role = ConstructionRole.fromAccessLevel(_store?.accessLevel);
    if (widget.lockedRole != null || _rolePicked || role == null || role == _role || !mounted) return;
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    final metreSite = _metreSite;
    return ImmoTabScaffold(
      items: [for (final t in ConstructionTab.values) t.navItem(_role)],
      index: _tab.index,
      onIndexChanged: (i) => _openTab(ConstructionTab.values[i]),
      pageBuilder: (context, i) => _page(ConstructionTab.values[i]),
      overlay: metreSite == null
          ? null
          : MetreScreen(
              site: metreSite,
              store: _store!,
              onClose: () => setState(() => _metreSite = null),
            ),
    );
  }

  Widget _page(ConstructionTab tab) {
    final isSupplier = _role == ConstructionRole.supplier;
    return switch (tab) {
      ConstructionTab.home => switch (_role) {
          ConstructionRole.supplier =>
            SupplierHomeScreen(store: _store!, onRoleChanged: _onRoleChanged, onOpenTab: _openTab),
          ConstructionRole.chefSite =>
            ChefSiteHomeScreen(store: _store!, onRoleChanged: _onRoleChanged, onOpenTab: _openTab),
          ConstructionRole.superviseur =>
            SuperviseurHomeScreen(store: _store!, onRoleChanged: _onRoleChanged, onOpenTab: _openTab),
          ConstructionRole.moyensGeneraux =>
            MoyensGenerauxHomeScreen(store: _store!, onRoleChanged: _onRoleChanged, onOpenTab: _openTab),
        },
      ConstructionTab.work when _role == ConstructionRole.superviseur => DemandesScreen(store: _store!),
      ConstructionTab.work when _role == ConstructionRole.moyensGeneraux => AchatsScreen(store: _store!),
      ConstructionTab.work when _role == ConstructionRole.supplier => SupplierOrdersScreen(store: _store!),
      ConstructionTab.work => ConstructionWorkScreen(
          role: _role,
          store: _store!,
          onOpenMetre: (site) => setState(() => _metreSite = site),
        ),
      ConstructionTab.messages => const MessagesScreen(),
      ConstructionTab.payments => isSupplier
          ? const supplier_pay.PaymentsScreen()
          : const chef_pay.PaymentsScreen(),
      ConstructionTab.account => isSupplier
          ? const supplier.AccountScreen()
          : chef.AccountScreen(roleLabel: _role.label),
    };
  }
}
