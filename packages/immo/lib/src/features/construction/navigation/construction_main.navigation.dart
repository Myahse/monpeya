import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/messaging/screens/messages.screen.dart';
import 'package:immo/src/features/construction/screens/chef_site/screens/account.screen.dart' as chef;
import 'package:immo/src/features/construction/screens/chef_site/screens/chef_site_home.screen.dart';
import 'package:immo/src/features/construction/screens/chef_site/screens/payments.screen.dart' as chef_pay;
import 'package:immo/src/features/construction/screens/construction_work.screen.dart';
import 'package:immo/src/features/construction/screens/supplier/screens/account.screen.dart' as supplier;
import 'package:immo/src/features/construction/screens/supplier/screens/payments.screen.dart' as supplier_pay;
import 'package:immo/src/features/construction/screens/supplier/screens/supplier_home.screen.dart';
import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// Role-based tab navigator — same shell as Mr Immo Location.
class ConstructionMainNavigation extends StatefulWidget {
  const ConstructionMainNavigation({
    super.key,
    this.initialRole = ConstructionRole.supplier,
    this.initialTab = ConstructionTab.home,
  });

  final ConstructionRole initialRole;
  final ConstructionTab initialTab;

  @override
  State<ConstructionMainNavigation> createState() =>
      _ConstructionMainNavigationState();
}

class _ConstructionMainNavigationState extends State<ConstructionMainNavigation> {
  late ConstructionRole _role = widget.initialRole;
  late ConstructionTab _tab = widget.initialTab;

  void _openTab(ConstructionTab tab) => setState(() => _tab = tab);

  void _setRole(ConstructionRole role) => setState(() => _role = role);

  @override
  Widget build(BuildContext context) {
    return ImmoTabScaffold(
      items: [for (final t in ConstructionTab.values) t.navItem(_role)],
      index: _tab.index,
      onIndexChanged: (i) => _openTab(ConstructionTab.values[i]),
      pageBuilder: (context, i) => _page(ConstructionTab.values[i]),
    );
  }

  Widget _page(ConstructionTab tab) {
    final isSupplier = _role == ConstructionRole.supplier;
    return switch (tab) {
      ConstructionTab.home => isSupplier
          ? SupplierHomeScreen(onRoleChanged: _setRole, onOpenTab: _openTab)
          : ChefSiteHomeScreen(onRoleChanged: _setRole, onOpenTab: _openTab),
      ConstructionTab.work => ConstructionWorkScreen(role: _role),
      ConstructionTab.messages => const MessagesScreen(),
      ConstructionTab.payments => isSupplier
          ? const supplier_pay.PaymentsScreen()
          : const chef_pay.PaymentsScreen(),
      ConstructionTab.account => isSupplier
          ? const supplier.AccountScreen()
          : const chef.AccountScreen(),
    };
  }
}
