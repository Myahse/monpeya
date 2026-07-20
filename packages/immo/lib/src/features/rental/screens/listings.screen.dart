import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/auth/rental.session.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental_profile_role.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/models/rental.tenant.dart';
import 'package:immo/src/features/rental/services/rental_api.service.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/property_card.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_profile_picker.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_seeker_property_tile.widget.dart';
import 'package:immo/src/features/rental/widgets/tenant_card.widget.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({
    super.key,
    this.onPropertySelect,
    this.onCreateListing,
    this.onCreateTenant,
    this.onViewTenant,
  });

  final ValueChanged<String>? onPropertySelect;
  final VoidCallback? onCreateListing;
  final VoidCallback? onCreateTenant;
  final ValueChanged<String>? onViewTenant;

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  List<RentalProperty> _properties = const [];
  List<RentalTenant> _tenants = const [];
  String? _error;
  bool _loading = false;

  // Seeker filters
  final _searchCtrl = TextEditingController();
  String? _selectedCity;
  List<String> _cityOptions = const [];

  RentalSession? _session;

  RentalApiService get _api {
    final session = _session;
    assert(session != null, 'RentalSession not ready');
    return session!.api;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = RentalSessionScope.of(context);
    if (!identical(_session, session)) {
      _session?.removeListener(_onSessionChanged);
      _session = session;
      _session!.addListener(_onSessionChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
    _maybeLoad();
  }

  void _maybeLoad() {
    final session = _session;
    if (session == null || !session.hasProfileRole) return;
    _load();
  }

  Future<void> _onProfileSelected(RentalProfileRole role) async {
    await _session?.setProfileRole(role);
  }

  Future<void> _switchProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: RentalTheme.sheetWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: RentalProfilePicker(
          onSelect: (role) {
            Navigator.pop(context);
            _onProfileSelected(role);
          },
        ),
      ),
    );
  }

  Future<void> _load() async {
    final session = _session;
    final role = session?.profileRole;
    if (role == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    if (role == RentalProfileRole.landlord) {
      await Future.wait([_loadLandlordProperties(), _loadTenants()]);
    } else {
      await _loadSeekerProperties();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadLandlordProperties() async {
    final session = _session;
    if (session == null) return;
    try {
      final items = await _api.properties.fetchMyProperties(ownerUserId: session.userId);
      if (!mounted) return;
      setState(() => _properties = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadTenants() async {
    final session = _session;
    if (session == null) return;
    try {
      final items = await _api.tenants.fetchTenants(userId: session.userId);
      if (!mounted) return;
      setState(() => _tenants = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _tenants = const []);
    }
  }

  Future<void> _loadSeekerProperties() async {
    try {
      final query = _searchCtrl.text.trim();
      final items = await _api.properties.fetchAvailableProperties(
        search: query.isEmpty ? null : query,
        city: _selectedCity,
      );
      if (!mounted) return;

      final cities = items
          .map((p) => p.city.trim())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _properties = items;
        _cityOptions = cities;
        if (_selectedCity != null && !cities.contains(_selectedCity)) {
          _selectedCity = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = RentalSessionScope.of(context);
    final role = session.profileRole;

    if (role == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ColoredBox(
          color: RentalTheme.surface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(decoration: BoxDecoration(gradient: RentalTheme.headerGradient)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RentalHomeHeader(
                    title: 'Mr Immo Location',
                    subtitle: 'Choisissez votre profil',
                  ),
                  Expanded(
                    child: RentalWhiteSheet(
                      topOverlap: 12,
                      child: RentalProfilePicker(onSelect: _onProfileSelected),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: RentalTheme.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: BoxDecoration(gradient: RentalTheme.headerGradient)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RentalHomeHeader(
                  title: role.homeTitle,
                  subtitle: role.homeSubtitle,
                  onSwitchProfile: _switchProfile,
                  onNotifications: () {},
                ),
                Expanded(
                  child: RentalWhiteSheet(
                    topOverlap: 12,
                    child: role == RentalProfileRole.landlord
                        ? _LandlordBody(
                            loading: _loading,
                            error: _error,
                            properties: _properties,
                            tenants: _tenants,
                            onRefresh: _load,
                            onRetryProperties: _loadLandlordProperties,
                            onPropertySelect: widget.onPropertySelect,
                            onCreateListing: widget.onCreateListing,
                            onCreateTenant: widget.onCreateTenant,
                            onViewTenant: widget.onViewTenant,
                          )
                        : _SeekerBody(
                            loading: _loading,
                            error: _error,
                            properties: _properties,
                            cityOptions: _cityOptions,
                            selectedCity: _selectedCity,
                            searchCtrl: _searchCtrl,
                            onRefresh: _load,
                            onSearch: _loadSeekerProperties,
                            onCitySelected: (city) {
                              setState(() {
                                _selectedCity = _selectedCity == city ? null : city;
                              });
                              _loadSeekerProperties();
                            },
                            onPropertySelect: widget.onPropertySelect,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LandlordBody extends StatelessWidget {
  const _LandlordBody({
    required this.loading,
    required this.error,
    required this.properties,
    required this.tenants,
    required this.onRefresh,
    required this.onRetryProperties,
    this.onPropertySelect,
    this.onCreateListing,
    this.onCreateTenant,
    this.onViewTenant,
  });

  final bool loading;
  final String? error;
  final List<RentalProperty> properties;
  final List<RentalTenant> tenants;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryProperties;
  final ValueChanged<String>? onPropertySelect;
  final VoidCallback? onCreateListing;
  final VoidCallback? onCreateTenant;
  final ValueChanged<String>? onViewTenant;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: RentalTheme.greenMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: RentalTheme.spacingMd,
          bottom: RentalTheme.scrollBottomPad,
        ),
        children: [
          RentalSectionHeader(
            title: 'Mes biens',
            subtitle: 'Gérez vos annonces',
            actionLabel: properties.isNotEmpty ? 'Voir tout' : null,
            onAction: () {},
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          if (loading && properties.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: RentalTheme.greenMid)),
            )
          else if (error != null)
            _ErrorBlock(message: error!, onRetry: onRetryProperties)
          else if (properties.isEmpty)
            _EmptyProperties(onCreate: onCreateListing)
          else ...[
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  return RentalPropertyCard(
                    property: property,
                    onTap: () => onPropertySelect?.call(property.id),
                  );
                },
              ),
            ),
            const SizedBox(height: RentalTheme.spacingMd),
            RentalGradientPillButton(label: 'Publier un bien', onPressed: onCreateListing),
          ],
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Locataires',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: RentalTheme.textPrimary,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RentalTheme.addTenantGradient,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCreateTenant,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: RentalTheme.spacingMd,
                          vertical: RentalTheme.spacingXs,
                        ),
                        child: Text(
                          '+ Ajouter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          if (tenants.isEmpty)
            _EmptyTenants(onCreate: onCreateTenant)
          else ...[
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
                itemCount: tenants.length,
                itemBuilder: (context, index) {
                  final tenant = tenants[index];
                  return RentalTenantCard(
                    tenant: tenant,
                    onTap: () => onViewTenant?.call(tenant.id),
                  );
                },
              ),
            ),
            const SizedBox(height: RentalTheme.spacingMd),
            RentalGradientPillButton(label: 'Ajouter un locataire', onPressed: onCreateTenant),
          ],
        ],
      ),
    );
  }
}

class _SeekerBody extends StatelessWidget {
  const _SeekerBody({
    required this.loading,
    required this.error,
    required this.properties,
    required this.cityOptions,
    required this.selectedCity,
    required this.searchCtrl,
    required this.onRefresh,
    required this.onSearch,
    required this.onCitySelected,
    this.onPropertySelect,
  });

  final bool loading;
  final String? error;
  final List<RentalProperty> properties;
  final List<String> cityOptions;
  final String? selectedCity;
  final TextEditingController searchCtrl;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSearch;
  final ValueChanged<String> onCitySelected;
  final ValueChanged<String>? onPropertySelect;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: RentalTheme.greenMid,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                RentalTheme.spacingLg,
                RentalTheme.spacingMd,
                RentalTheme.spacingLg,
                RentalTheme.spacingSm,
              ),
              child: TextField(
                controller: searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, quartier…',
                  prefixIcon: const Icon(Icons.search, color: RentalTheme.textSecondary),
                  filled: true,
                  fillColor: RentalTheme.searchBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          if (cityOptions.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
                  itemCount: cityOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final city = cityOptions[index];
                    final selected = selectedCity == city;
                    return FilterChip(
                      label: Text(city),
                      selected: selected,
                      onSelected: (_) => onCitySelected(city),
                      selectedColor: RentalTheme.greenMid.withValues(alpha: 0.15),
                      checkmarkColor: RentalTheme.greenMid,
                      labelStyle: TextStyle(
                        color: selected ? RentalTheme.greenMid : RentalTheme.textPrimary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                RentalTheme.spacingLg,
                RentalTheme.spacingMd,
                RentalTheme.spacingLg,
                RentalTheme.spacingSm,
              ),
              child: Text(
                selectedCity != null
                    ? 'Biens disponibles à $selectedCity'
                    : 'Biens disponibles',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: RentalTheme.textPrimary,
                ),
              ),
            ),
          ),
          if (loading && properties.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: RentalTheme.greenMid)),
            )
          else if (error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorBlock(message: error!, onRetry: onSearch),
            )
          else if (properties.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(RentalTheme.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 56, color: RentalTheme.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'Aucun bien disponible pour ces critères.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: RentalTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final property = properties[index];
                  return RentalSeekerPropertyTile(
                    property: property,
                    onTap: () => onPropertySelect?.call(property.id),
                  );
                },
                childCount: properties.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: RentalTheme.scrollBottomPad)),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg, vertical: 32),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE53E3E))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyProperties extends StatelessWidget {
  const _EmptyProperties({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mon bien',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RentalTheme.textPrimary),
            ),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          Container(
            width: 280,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.home_work_outlined,
              size: 72,
              color: RentalTheme.greenMid.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          const Text(
            'Vous n’avez pas encore de bien. Créez-en un.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: RentalTheme.textSecondary),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          RentalGradientPillButton(label: 'Publier un bien', onPressed: onCreate),
        ],
      ),
    );
  }
}

class _EmptyTenants extends StatelessWidget {
  const _EmptyTenants({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
      child: Column(
        children: [
          Container(
            width: 280,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.people_outline, size: 64, color: RentalTheme.greenAccent.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          const Text(
            'Aucun locataire. Ajoutez votre premier locataire.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: RentalTheme.textSecondary),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          RentalGradientPillButton(
            label: 'Ajouter locataire',
            onPressed: onCreate,
            widthFactor: 0.3,
          ),
        ],
      ),
    );
  }
}
