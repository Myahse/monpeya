import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/screens/dashboard.screen.dart';
import 'package:immo/src/features/collection/screens/properties.screen.dart';
import 'package:immo/src/features/collection/screens/rent_collection.screen.dart';

enum CollectionRoute {
  hub,
  properties,
  rentCollection,
}

/// Hub navigation — mirrors collection-app `App.tsx` main flow.
class CollectionNavigator extends StatefulWidget {
  const CollectionNavigator({super.key});

  @override
  State<CollectionNavigator> createState() => _CollectionNavigatorState();
}

class _CollectionNavigatorState extends State<CollectionNavigator> {
  CollectionRoute _route = CollectionRoute.hub;
  String? _activePropertyId;
  String? _activeContractId;

  void _goHub() => setState(() {
        _route = CollectionRoute.hub;
        _activePropertyId = null;
        _activeContractId = null;
      });

  @override
  Widget build(BuildContext context) {
    return switch (_route) {
      CollectionRoute.hub => _CollectionHub(
          onProperties: () => setState(() => _route = CollectionRoute.properties),
          onRentCollection: () =>
              setState(() => _route = CollectionRoute.rentCollection),
        ),
      CollectionRoute.properties => PropertiesScreen(
          onBack: _goHub,
          onSelectProperty: (id) => setState(() {
            _activePropertyId = id;
            _route = CollectionRoute.rentCollection;
          }),
          onViewPayments: (propertyId, contractId) => setState(() {
            _activePropertyId = propertyId;
            _activeContractId = contractId;
            _route = CollectionRoute.rentCollection;
          }),
        ),
      CollectionRoute.rentCollection => RentCollectionScreen(
          onBack: _activePropertyId == null ? _goHub : () => setState(() => _route = CollectionRoute.properties),
          propertyId: _activePropertyId,
          contractId: _activeContractId,
        ),
    };
  }
}

class _CollectionHub extends StatelessWidget {
  const _CollectionHub({
    required this.onProperties,
    required this.onRentCollection,
  });

  final VoidCallback onProperties;
  final VoidCallback onRentCollection;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const DashboardScreen(),
            const SizedBox(height: 8),
            Text(
              'Services',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _HubCard(
              title: 'Biens',
              subtitle: 'Parc immobilier, lots, locataires',
              icon: Icons.apartment_outlined,
              color: ImmoBrand.collectionPrimary,
              onTap: onProperties,
            ),
            const SizedBox(height: 12),
            _HubCard(
              title: 'Recouvrement loyers',
              subtitle: 'Échéances, relances, encaissements',
              icon: Icons.receipt_long_outlined,
              color: ImmoBrand.collectionDark,
              onTap: onRentCollection,
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
