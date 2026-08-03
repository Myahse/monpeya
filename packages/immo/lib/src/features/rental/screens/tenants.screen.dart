import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.tenant.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';
import 'package:immo/src/features/rental/widgets/tenant_card.widget.dart';

/// Business Locataires tab — list of tenants for the landlord.
class TenantsScreen extends StatefulWidget {
  const TenantsScreen({
    super.key,
    this.onViewTenant,
    this.onCreateTenant,
  });

  final ValueChanged<String>? onViewTenant;
  final VoidCallback? onCreateTenant;

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  List<RentalTenant> _tenants = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = RentalSessionScope.of(context);
    if (session.guestMode || session.userId == null || session.userId!.isEmpty) {
      setState(() {
        _tenants = const [];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items =
          await session.api.tenants.fetchTenants(userId: session.userId);
      if (!mounted) return;
      setState(() {
        _tenants = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final session = RentalSessionScope.of(context);
    final isGuest = session.guestMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: b.bg,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Locataires',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: b.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isGuest
                                ? 'Connectez-vous pour gérer vos locataires'
                                : 'Gérez les locataires de vos biens',
                            style: TextStyle(color: b.muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (!isGuest)
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: RentalTheme.green,
                  child: _buildBody(b, isGuest),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ImmoRentalPalette b, bool isGuest) {
    final bottom = RentalBottomNavigation.contentBottomPadding(context);

    if (_loading && _tenants.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: RentalTheme.green)),
        ],
      );
    }

    if (_error != null && _tenants.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 48, 24, bottom),
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: b.danger),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ),
        ],
      );
    }

    if (_tenants.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 32, 24, bottom),
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: b.searchFill,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.people_outline,
              size: 56,
              color: RentalTheme.green.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          Text(
            isGuest
                ? 'Connectez-vous pour voir et ajouter des locataires.'
                : 'Aucun locataire. Ajoutez votre premier locataire.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: b.muted),
          ),
          if (!isGuest) ...[
            const SizedBox(height: RentalTheme.spacingMd),
            RentalGradientPillButton(
              label: 'Ajouter locataire',
              onPressed: widget.onCreateTenant,
              widthFactor: 0.55,
            ),
          ],
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _tenants.length,
      itemBuilder: (context, index) {
        final tenant = _tenants[index];
        return RentalTenantCard(
          tenant: tenant,
          onTap: () => widget.onViewTenant?.call(tenant.id),
        );
      },
    );
  }
}
