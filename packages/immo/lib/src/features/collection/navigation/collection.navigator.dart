import 'package:flutter/material.dart';

import 'package:immo/src/features/collection/screens/dashboard.screen.dart';
import 'package:immo/src/features/collection/screens/properties.screen.dart';
import 'package:immo/src/features/collection/screens/rent_collection.screen.dart';
import 'package:immo/src/features/collection/services/collection.store.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

enum CollectionTab { home, properties, rentCollection, account }

/// Tab navigation — same shell as Mr Immo Location.
class CollectionNavigator extends StatefulWidget {
  const CollectionNavigator({super.key});

  @override
  State<CollectionNavigator> createState() => _CollectionNavigatorState();
}

class _CollectionNavigatorState extends State<CollectionNavigator> {
  CollectionTab _tab = CollectionTab.home;
  String? _activePropertyId;
  CollectionStore? _store;
  bool _requested = false;
  String? _requestedFor;

  static const _items = [
    ImmoNavItem(label: 'Accueil', icon: Icons.home_outlined, selectedIcon: Icons.home_rounded),
    ImmoNavItem(label: 'Biens', icon: Icons.apartment_outlined, selectedIcon: Icons.apartment_rounded),
    ImmoNavItem(label: 'Loyers', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded),
    ImmoNavItem(label: 'Profil', icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = ImmoModuleSessionScope.of(context);
    final store = _store ??= CollectionStore(client: session.client);
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

  void _open(CollectionTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final store = _store!;
    return ImmoTabScaffold(
      items: _items,
      index: _tab.index,
      onIndexChanged: (i) => _open(CollectionTab.values[i]),
      pageBuilder: (context, i) => switch (CollectionTab.values[i]) {
        CollectionTab.home => DashboardScreen(
            store: store,
            onOpenProperties: () => _open(CollectionTab.properties),
            onOpenCollection: () => setState(() {
              _activePropertyId = null;
              _tab = CollectionTab.rentCollection;
            }),
          ),
        CollectionTab.properties => PropertiesScreen(
            store: store,
            onSelectProperty: (id) => setState(() {
              _activePropertyId = id;
              _tab = CollectionTab.rentCollection;
            }),
          ),
        CollectionTab.rentCollection => RentCollectionScreen(
            store: store,
            propertyId: _activePropertyId,
            onClearProperty: () => setState(() => _activePropertyId = null),
          ),
        CollectionTab.account => const _CollectionAccount(),
      },
    );
  }
}

class _CollectionAccount extends StatelessWidget {
  const _CollectionAccount();

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    final name = (session.displayName ?? '').trim();
    return ImmoAccountView(
      moduleLabel: 'Mr Immo Collection',
      name: name.isEmpty ? 'Invité' : name,
      phone: session.phone,
      roleLabel: 'Gestionnaire',
      guest: session.guestMode,
    );
  }
}
