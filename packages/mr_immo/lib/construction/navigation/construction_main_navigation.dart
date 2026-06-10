import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../messaging/screens/messages_screen.dart';
import '../screens/chef_site/account_screen.dart' as chef;
import '../screens/chef_site/chef_site_home_screen.dart';
import '../screens/chef_site/payments_screen.dart' as chef_pay;
import '../screens/supplier/account_screen.dart' as supplier;
import '../screens/supplier/payments_screen.dart' as supplier_pay;
import '../screens/supplier/supplier_home_screen.dart';
import 'construction_tab.dart';

/// Role-based tab navigator — mirrors construction-app `MainNavigation.tsx`.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        indicatorColor: ImmoBrand.constructionPrimary.withValues(alpha: 0.18),
        onDestinationSelected: (i) =>
            setState(() => _tab = ConstructionTab.values[i]),
        destinations: [
          for (final t in ConstructionTab.values)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
      floatingActionButton: _tab == ConstructionTab.home
          ? FloatingActionButton.small(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ListTile(title: Text('Rôle', style: TextStyle(fontWeight: FontWeight.w700))),
                        for (final r in ConstructionRole.values)
                          ListTile(
                            leading: Icon(_role == r ? Icons.check_circle : Icons.circle_outlined),
                            title: Text(r.label),
                            onTap: () {
                              setState(() {
                                _role = r;
                                _tab = ConstructionTab.home;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
              backgroundColor: ImmoBrand.constructionPrimary,
              child: const Icon(Icons.swap_horiz, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    final isSupplier = _role == ConstructionRole.supplier;
    return switch (_tab) {
      ConstructionTab.home => isSupplier
          ? const SupplierHomeScreen()
          : const ChefSiteHomeScreen(),
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
