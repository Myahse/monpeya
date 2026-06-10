import 'package:flutter/material.dart';

import '../../host/immo_host_bridge.dart';
import '../creation/screens/create_listing_screen.dart';
import '../creation/screens/create_tenant_screen.dart';
import '../messaging/screens/messages_screen.dart';
import '../screens/contract_detail_screen.dart';
import '../screens/contracts_screen.dart';
import '../screens/listings_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/property_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tenant_detail_screen.dart';
import '../theme/rental_theme.dart';
import 'rental_bottom_navigation.dart';
import 'rental_tab.dart';

/// Main tab navigator — mirrors rental-app `MainNavigation.tsx`.
class RentalMainNavigation extends StatefulWidget {
  const RentalMainNavigation({super.key, this.initialTab = RentalTab.home});

  final RentalTab initialTab;

  @override
  State<RentalMainNavigation> createState() => _RentalMainNavigationState();
}

class _RentalMainNavigationState extends State<RentalMainNavigation> {
  late RentalTab _tab = widget.initialTab;
  String? _selectedPropertyId;
  bool _showContracts = false;
  String? _selectedContractId;
  bool _showCreateListing = false;
  bool _showCreateTenant = false;
  String? _selectedTenantId;
  int _listingsRefreshKey = 0;
  bool _messagesInChat = false;

  void _onTab(RentalTab tab) {
    setState(() {
      _tab = tab;
      _selectedPropertyId = null;
      _messagesInChat = false;
    });
  }

  bool get _hideBottomNav =>
      _showCreateTenant ||
      _showCreateListing ||
      _selectedContractId != null ||
      _showContracts ||
      _selectedTenantId != null ||
      _selectedPropertyId != null ||
      _messagesInChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RentalTheme.surface,
      body: _buildBody(),
      bottomNavigationBar: _hideBottomNav
          ? null
          : RentalBottomNavigation(activeTab: _tab, onTab: _onTab),
    );
  }

  Widget _buildBody() {
    if (_showCreateTenant) {
      return CreateTenantScreen(
        onClose: () => setState(() => _showCreateTenant = false),
        onCreated: () => setState(() {
          _showCreateTenant = false;
          _listingsRefreshKey++;
        }),
      );
    }
    if (_showCreateListing) {
      return CreateListingScreen(
        onClose: () => setState(() => _showCreateListing = false),
        onPublished: () => setState(() => _listingsRefreshKey++),
      );
    }
    if (_selectedContractId != null) {
      return ContractDetailScreen(
        contractId: _selectedContractId!,
        onBack: () => setState(() => _selectedContractId = null),
      );
    }
    if (_showContracts) {
      return ContractsScreen(
        onBack: () => setState(() => _showContracts = false),
        onViewContract: (id) => setState(() => _selectedContractId = id),
      );
    }
    if (_selectedTenantId != null) {
      return TenantDetailScreen(
        tenantId: _selectedTenantId!,
        onBack: () => setState(() => _selectedTenantId = null),
      );
    }
    if (_selectedPropertyId != null) {
      return PropertyDetailScreen(
        propertyId: _selectedPropertyId!,
        onBack: () => setState(() => _selectedPropertyId = null),
      );
    }

    return switch (_tab) {
      RentalTab.home => ListingsScreen(
          key: ValueKey('listings-$_listingsRefreshKey'),
          onPropertySelect: (id) => setState(() => _selectedPropertyId = id),
          onCreateListing: () => setState(() => _showCreateListing = true),
          onCreateTenant: () => setState(() => _showCreateTenant = true),
          onViewTenant: (id) => setState(() => _selectedTenantId = id),
        ),
      RentalTab.messages => MessagesScreen(
          onChatModeChanged: (inChat) {
            if (_messagesInChat != inChat) {
              setState(() => _messagesInChat = inChat);
            }
          },
        ),
      RentalTab.payments => const PaymentsScreen(),
      RentalTab.account => SettingsScreen(
          onNavigateToContracts: () => setState(() => _showContracts = true),
          onCreateTenant: () => setState(() => _showCreateTenant = true),
          onExitModule: () => ImmoHostBridge.exitModule(context),
        ),
    };
  }
}
