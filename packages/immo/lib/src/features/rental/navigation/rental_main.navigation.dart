import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/creation/screens/create_listing.screen.dart';
import 'package:immo/src/features/rental/creation/screens/create_tenant.screen.dart';
import 'package:immo/src/features/rental/messaging/screens/messages.screen.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/models/rental_profile_role.dart';
import 'package:immo/src/features/rental/screens/contract_detail.screen.dart';
import 'package:immo/src/features/rental/screens/contracts.screen.dart';
import 'package:immo/src/features/rental/screens/favorites.screen.dart';
import 'package:immo/src/features/rental/screens/listings.screen.dart';
import 'package:immo/src/features/rental/screens/map.screen.dart';
import 'package:immo/src/features/rental/screens/payments.screen.dart';
import 'package:immo/src/features/rental/screens/property_detail.screen.dart';
import 'package:immo/src/features/rental/screens/rental_profile.screen.dart';
import 'package:immo/src/features/rental/screens/search.screen.dart';
import 'package:immo/src/features/rental/screens/tenant_detail.screen.dart';
import 'package:immo/src/features/rental/screens/tenants.screen.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/navigation/rental.tab.dart';

/// Main tab navigator — Mr Immo Location shell.
class RentalMainNavigation extends StatefulWidget {
  const RentalMainNavigation({super.key, this.initialTab = RentalTab.home});

  final RentalTab initialTab;

  @override
  State<RentalMainNavigation> createState() => _RentalMainNavigationState();
}

class _RentalMainNavigationState extends State<RentalMainNavigation> {
  late RentalTab _tab = widget.initialTab;
  final Set<RentalTab> _visitedTabs = {};
  String? _selectedPropertyId;
  RentalProperty? _selectedProperty;
  bool _showContracts = false;
  String? _selectedContractId;
  bool _showCreateListing = false;
  bool _showCreateTenant = false;
  String? _selectedTenantId;
  bool _showPayments = false;
  bool _showMessages = false;
  bool _messagesInChat = false;

  @override
  void initState() {
    super.initState();
    _visitedTabs.add(widget.initialTab);
  }

  void _onTab(RentalTab tab) {
    setState(() {
      _tab = tab;
      _visitedTabs.add(tab);
      // Keep tab pages mounted — only clear overlays when changing tabs.
      _selectedPropertyId = null;
      _selectedProperty = null;
      _showPayments = false;
      _showMessages = false;
      _messagesInChat = false;
      _showContracts = false;
      _selectedContractId = null;
      _selectedTenantId = null;
      _showCreateListing = false;
      _showCreateTenant = false;
    });
  }

  bool get _hideBottomNav =>
      _showCreateTenant ||
      _showCreateListing ||
      _selectedContractId != null ||
      _showContracts ||
      _selectedTenantId != null ||
      _selectedPropertyId != null ||
      _showPayments ||
      _showMessages ||
      _messagesInChat;

  void _openProperty(RentalProperty property) {
    setState(() {
      _selectedPropertyId = property.id;
      _selectedProperty = property;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = RentalSessionScope.of(context);
    // Guests always get client tabs (browse); business tabs need Immo auth.
    final tabs = RentalTab.tabsFor(
      session.guestMode ? RentalProfileRole.seeker : session.profileRole,
    );
    final currentTab = tabs.contains(_tab) ? _tab : RentalTab.home;
    if (currentTab != _tab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tab != RentalTab.home) {
          setState(() => _tab = RentalTab.home);
        }
      });
    }
    final tabIndex = tabs.indexOf(currentTab).clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: ImmoBrand.rentalOf(context).bg,
      body: Stack(
        children: [
          // Full-bleed under the frosted nav so maps / lists can blur through.
          Positioned.fill(
            child: ClipRect(
              child: IndexedStack(
                index: tabIndex,
                sizing: StackFit.expand,
                children: [
                  for (final tab in tabs)
                    _visitedTabs.contains(tab)
                        ? KeyedSubtree(
                            key: ValueKey(tab),
                            child: _buildTabPage(tab),
                          )
                        : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          if (_overlay != null)
            Positioned.fill(
              child: ColoredBox(
                color: ImmoBrand.rentalOf(context).bg,
                child: _overlay!,
              ),
            ),
          if (!_hideBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RentalBottomNavigation(
                current: currentTab,
                tabs: tabs,
                onChanged: _onTab,
              ),
            ),
        ],
      ),
    );
  }

  Widget? get _overlay {
    if (_showCreateTenant) {
      return CreateTenantScreen(
        onClose: () => setState(() => _showCreateTenant = false),
        onCreated: () => setState(() => _showCreateTenant = false),
      );
    }
    if (_showCreateListing) {
      return CreateListingScreen(
        onClose: () => setState(() => _showCreateListing = false),
        onPublished: () => setState(() => _showCreateListing = false),
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
    if (_showPayments) {
      return PaymentsScreen(
        onBack: () => setState(() => _showPayments = false),
      );
    }
    if (_showMessages) {
      return ColoredBox(
        color: ImmoBrand.rentalOf(context).bg,
        child: Column(
          children: [
            Material(
              color: RentalTheme.greenDark,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          _showMessages = false;
                          _messagesInChat = false;
                        }),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const Text(
                        'Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: MessagesScreen(
                onChatModeChanged: (inChat) {
                  if (_messagesInChat != inChat) {
                    setState(() => _messagesInChat = inChat);
                  }
                },
              ),
            ),
          ],
        ),
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
        initialProperty: _selectedProperty,
        onBack: () => setState(() {
          _selectedPropertyId = null;
          _selectedProperty = null;
        }),
      );
    }
    return null;
  }

  Widget _buildTabPage(RentalTab tab) {
    return switch (tab) {
      RentalTab.home => ListingsScreen(
          onPropertySelect: _openProperty,
          onCreateListing: () => setState(() => _showCreateListing = true),
          onCreateTenant: () => setState(() => _showCreateTenant = true),
          onViewTenant: (id) => setState(() => _selectedTenantId = id),
          onSeeAll: () => _onTab(RentalTab.search),
        ),
      RentalTab.search => SearchScreen(
          onPropertySelect: _openProperty,
        ),
      RentalTab.favorites => FavoritesScreen(
          onPropertySelect: _openProperty,
        ),
      RentalTab.tenants => TenantsScreen(
          onViewTenant: (id) => setState(() => _selectedTenantId = id),
          onCreateTenant: () => setState(() => _showCreateTenant = true),
        ),
      RentalTab.map => MapScreen(
          onPropertySelect: _openProperty,
        ),
      RentalTab.account => RentalProfileScreen(
          onNavigateToContracts: () => setState(() => _showContracts = true),
          onCreateTenant: () => setState(() => _showCreateTenant = true),
          onCreateListing: () => setState(() => _showCreateListing = true),
          onOpenFavorites: () => _onTab(RentalTab.favorites),
          onOpenPayments: () => setState(() => _showPayments = true),
        ),
    };
  }
}
