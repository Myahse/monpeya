import 'package:flutter/material.dart';

import 'package:grenier/src/presentation/widgets/grenier_ui.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';

/// Products the user follows.
class GrenierFollowsView extends StatelessWidget {
  const GrenierFollowsView({
    super.key,
    required this.products,
    required this.onOpen,
    required this.onUnfollow,
    required this.onBrowse,
  });

  final List<GrenierProduit> products;
  final ValueChanged<GrenierProduit> onOpen;
  final ValueChanged<GrenierProduit> onUnfollow;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return GrenierHeaderPage(
      header: const GrenierHeaderTitle(
        eyebrow: 'Mon Grenier',
        title: 'Produits suivis',
        subtitle: 'Retrouvez vite les prix qui comptent pour vous',
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 22, 20, GrenierPillNav.clearance(context)),
        children: [
          if (products.isEmpty)
            GrenierRise(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                decoration: grenierCard(),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: GrenierColors.soft, shape: BoxShape.circle),
                      child: const Icon(Icons.star_outline_rounded, color: GrenierColors.primary, size: 30),
                    ),
                    const SizedBox(height: 14),
                    const Text('Aucun produit suivi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Touchez l’étoile sur la fiche d’un produit pour le retrouver ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: GrenierColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final (i, p) in products.indexed)
              GrenierRise(
                delay: Duration(milliseconds: 60 * i),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GrenierPressable(
                    onTap: () => onOpen(p),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: grenierCard(),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(width: 56, height: 56, child: GrenierProductImage(product: p)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(
                                  '${p.unit}${p.market == null ? '' : ' · ${p.market}'}',
                                  style: const TextStyle(fontSize: 12.5, color: GrenierColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${GrenierProduit.formatAmount(p.price)} F',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          IconButton(
                            tooltip: 'Ne plus suivre',
                            onPressed: () => onUnfollow(p),
                            icon: const Icon(Icons.star_rounded, color: GrenierColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 4),
          GrenierRise(
            delay: const Duration(milliseconds: 120),
            child: OutlinedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Suivre un autre produit', style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: GrenierColors.primary,
                side: const BorderSide(color: Color(0xFFA7CFAA), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
