import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sim/src/data/models/sim_catalogue.model.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';
import 'package:sim/src/presentation/widgets/sim_shared_widgets.dart';

/// SIM home: brand hero with the pulsing shield, then the products.
class SimHomeView extends StatelessWidget {
  const SimHomeView({
    super.key,
    required this.products,
    required this.loading,
    required this.configured,
    required this.hasCards,
    required this.onBack,
    required this.onOpenCards,
    required this.onSelect,
    required this.onRetry,
  });

  final List<SimProduitCatalogue> products;
  final bool loading;
  final bool configured;
  final bool hasCards;
  final VoidCallback onBack;
  final VoidCallback onOpenCards;
  final ValueChanged<SimProduitCatalogue> onSelect;
  final VoidCallback onRetry;

  static IconData iconFor(String code) {
    final c = code.toLowerCase();
    if (c.contains('moto')) return Icons.two_wheeler_rounded;
    if (c.contains('auto')) return Icons.directions_car_rounded;
    if (c.contains('accident')) return Icons.health_and_safety_rounded;
    return Icons.shield_rounded;
  }

  static String? taglineFor(String code) {
    final c = code.toLowerCase();
    if (c.contains('moto')) return 'Responsabilité civile moto';
    if (c.contains('auto')) return 'Votre véhicule protégé';
    if (c.contains('accident')) return 'Frais médicaux après accident';
    return null;
  }

  static String? fromPrice(SimProduitCatalogue p) {
    final primes = p.formuleOptions().map((o) => o.prime).whereType<int>().where((v) => v > 0);
    if (primes.isEmpty) return null;
    final min = primes.reduce((a, b) => a < b ? a : b);
    final s = min.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return 'À partir de $s F';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SimBrand.background,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: SimBrand.primary,
                padding: EdgeInsets.fromLTRB(8, top + 4, 16, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Retour',
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                        const Spacer(),
                        const SimLogoBadge(),
                        const Spacer(),
                        if (hasCards)
                          TextButton.icon(
                            onPressed: onOpenCards,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: .16),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.credit_card_rounded, size: 16),
                            label: const Text('Mes cartes', style: TextStyle(fontWeight: FontWeight.w700)),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                    const SimShieldHero(),
                    const SimRise(
                      child: Column(
                        children: [
                          Text(
                            'Protégez ce qui compte',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Devis immédiat, paiement Peya Pay, carte sur votre téléphone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xE0FFFFFF), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              // Navy backdrop so the panel's rounded corners sit on the hero.
              child: ColoredBox(
                color: SimBrand.primary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
                  decoration: const BoxDecoration(
                    color: SimBrand.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SimRise(
                        delay: Duration(milliseconds: 100),
                        child: Text(
                          'Choisissez votre assurance',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator(color: SimBrand.primary)),
                        )
                      else if (products.isEmpty)
                        SimRise(
                          delay: const Duration(milliseconds: 160),
                          child: _Unavailable(configured: configured, onRetry: onRetry),
                        )
                      else
                        for (final (i, p) in products.indexed)
                          SimRise(
                            delay: Duration(milliseconds: 180 + i * 100),
                            child: _ProductCard(product: p, onTap: () => onSelect(p)),
                          ),
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final SimProduitCatalogue product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tagline = SimHomeView.taglineFor(product.code);
    final from = SimHomeView.fromPrice(product);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SimPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: simCardDecoration(),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: SimBrand.soft, borderRadius: BorderRadius.circular(16)),
                child: Icon(SimHomeView.iconFor(product.code), color: SimBrand.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.libelle.isNotEmpty ? product.libelle : product.code,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (tagline != null)
                      Text(tagline, style: const TextStyle(fontSize: 13, color: SimBrand.muted)),
                    if (from != null)
                      Text(from, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SimBrand.primary)),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: SimBrand.background, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, color: SimBrand.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.configured, required this.onRetry});

  final bool configured;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      decoration: simCardDecoration(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: SimBrand.soft, shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_rounded, color: SimBrand.primary, size: 30),
          ),
          const SizedBox(height: 14),
          const Text('Catalogue indisponible', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            configured
                ? 'Les produits SIM Assurances ne répondent pas. Vérifiez votre connexion.'
                : 'Le service SIM Assurances n’est pas encore configuré sur cette version.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: SimBrand.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: SimBrand.primary,
              side: const BorderSide(color: SimBrand.primary),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
