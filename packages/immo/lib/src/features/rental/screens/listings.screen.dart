import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/models/rental.tenant.dart';
import 'package:immo/src/features/rental/services/rental_api.service.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/property_card.widget.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';
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

  RentalApiService get _api => RentalSessionScope.of(context).api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadProperties(), _loadTenants()]);
  }

  Future<void> _loadProperties() async {
    setState(() => _error = null);
    try {
      final items = await _api.properties.fetchProperties();
      if (!mounted) return;
      setState(() => _properties = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadTenants() async {
    try {
      final userId = RentalSessionScope.of(context).userId;
      final items = await _api.tenants.fetchTenants(userId: userId);
      if (!mounted) return;
      setState(() => _tenants = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _tenants = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final sheetHeight = height * 0.82;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: RentalTheme.surface,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(gradient: RentalTheme.headerGradient)),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.15,
              child: RentalLandlordHeader(onNotifications: () {}),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: sheetHeight,
              child: RentalWhiteSheet(
                child: RefreshIndicator(
                  onRefresh: _load,
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
                        actionLabel: 'Voir tout',
                        onAction: () {},
                      ),
                      const SizedBox(height: RentalTheme.spacingMd),
                      if (_error != null)
                        _ErrorBlock(message: _error!, onRetry: _loadProperties)
                      else if (_properties.isEmpty)
                        _EmptyProperties(onCreate: widget.onCreateListing)
                      else ...[
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
                            itemCount: _properties.length,
                            itemBuilder: (context, index) {
                              final property = _properties[index];
                              return RentalPropertyCard(
                                property: property,
                                onTap: () => widget.onPropertySelect?.call(property.id),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: RentalTheme.spacingMd),
                        RentalGradientPillButton(
                          label: 'Publier un bien',
                          onPressed: widget.onCreateListing,
                        ),
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
                                  onTap: widget.onCreateTenant,
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
                      if (_tenants.isEmpty)
                        _EmptyTenants(onCreate: widget.onCreateTenant)
                      else ...[
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: RentalTheme.spacingLg),
                            itemCount: _tenants.length,
                            itemBuilder: (context, index) {
                              final tenant = _tenants[index];
                              return RentalTenantCard(
                                tenant: tenant,
                                onTap: () => widget.onViewTenant?.call(tenant.id),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: RentalTheme.spacingMd),
                        RentalGradientPillButton(
                          label: 'Ajouter un locataire',
                          onPressed: widget.onCreateTenant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
