import 'package:flutter/material.dart';

import 'package:grenier/src/core/host/grenier_host.bridge.dart';
import 'package:grenier/src/presentation/widgets/grenier_ui.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';

/// Home: one horizontal row of square product cards per market.
class GrenierMarketsView extends StatefulWidget {
  const GrenierMarketsView({
    super.key,
    required this.products,
    required this.profile,
    required this.flashId,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpen,
    required this.onAccount,
  });

  final List<GrenierProduit> products;
  final GrenierHostProfile? profile;
  final int? flashId;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<GrenierProduit> onOpen;
  final VoidCallback onAccount;

  @override
  State<GrenierMarketsView> createState() => _GrenierMarketsViewState();
}

class _GrenierMarketsViewState extends State<GrenierMarketsView> {
  String _query = '';

  Map<String, List<GrenierProduit>> get _byMarket {
    final q = _query.trim().toLowerCase();
    final map = <String, List<GrenierProduit>>{};
    for (final p in widget.products) {
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) continue;
      final m = (p.market == null || p.market!.trim().isEmpty) ? 'Autres' : p.market!.trim();
      map.putIfAbsent(m, () => []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length)),
    );
  }

  static String _updated(List<GrenierProduit> items) {
    final dates = items.map((p) => p.updatedAt).whereType<DateTime>().toList();
    if (dates.isEmpty) return '';
    final last = dates.reduce((a, b) => a.isAfter(b) ? a : b).toLocal();
    final now = DateTime.now();
    final sameDay = last.year == now.year && last.month == now.month && last.day == now.day;
    final hm = '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
    return sameDay ? ' · mis à jour à $hm' : ' · mis à jour le ${last.day}/${last.month}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final name = profile?.fullName.trim() ?? '';
    final markets = _byMarket;

    return GrenierHeaderPage(
      header: GrenierHeaderTitle(
        live: true,
        eyebrow: 'Mon Grenier · prix en direct',
        title: name.isEmpty ? 'Bienvenue' : 'Bienvenue, $name',
        subtitle: 'Les prix du jour dans vos marchés',
        trailing: Semantics(
          button: true,
          label: 'Mon compte',
          child: GrenierPressable(
            onTap: widget.onAccount,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: profile == null || profile.initials.isEmpty
                  ? const Icon(Icons.person_outline_rounded, color: Colors.white)
                  : Text(
                      profile.initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: GrenierColors.primary,
        onRefresh: () async => widget.onRetry(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 20, bottom: GrenierPillNav.clearance(context)),
          children: [
            GrenierRise(
              delay: const Duration(milliseconds: 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit',
                    prefixIcon: const Icon(Icons.search_rounded, color: GrenierColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: GrenierColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (widget.loading && widget.products.isEmpty)
              const _MarketsSkeleton()
            else if (widget.error != null && widget.products.isEmpty)
              _Message(
                icon: Icons.cloud_off_rounded,
                title: 'Prix indisponibles',
                message: 'Impossible de joindre Mon Grenier pour le moment.',
                action: 'Réessayer',
                onAction: widget.onRetry,
              )
            else if (markets.isEmpty)
              _Message(
                icon: Icons.search_off_rounded,
                title: _query.isEmpty ? 'Aucun produit' : 'Aucun résultat',
                message: _query.isEmpty
                    ? 'Les prix des marchés apparaîtront ici.'
                    : 'Aucun produit ne correspond à « $_query ».',
              )
            else
              for (final (i, entry) in markets.entries.indexed) ...[
                GrenierRise(
                  delay: Duration(milliseconds: 120 + i * 110),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marché ${entry.key}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${entry.value.length} produit${entry.value.length > 1 ? 's' : ''}${_updated(entry.value)}',
                          style: const TextStyle(fontSize: 12.5, color: GrenierColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: entry.value.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, c) {
                      final p = entry.value[c];
                      return GrenierRise(
                        offset: const Offset(28, 0),
                        delay: Duration(milliseconds: 180 + i * 110 + c * 70),
                        child: GrenierProductCard(
                          product: p,
                          flash: widget.flashId == p.id,
                          onTap: () => widget.onOpen(p),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
              ],
          ],
        ),
      ),
    );
  }
}

class _MarketsSkeleton extends StatefulWidget {
  const _MarketsSkeleton();

  @override
  State<_MarketsSkeleton> createState() => _MarketsSkeletonState();
}

class _MarketsSkeletonState extends State<_MarketsSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final color = Color.lerp(const Color(0xFFE9ECE9), const Color(0xFFF3F5F3), _c.value)!;
        Widget box(double w, double h) => Container(
              width: w,
              height: h,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(h > 40 ? 18 : 8)),
            );
        return Column(
          children: [
            for (var r = 0; r < 3; r++)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(150, 18),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var c = 0; c < 3; c++) ...[box(140, 140), const SizedBox(width: 12)],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
        decoration: grenierCard(),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: GrenierColors.soft, shape: BoxShape.circle),
              child: Icon(icon, color: GrenierColors.primary, size: 30),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GrenierColors.muted, height: 1.4),
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(action!, style: const TextStyle(fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GrenierColors.primary,
                  side: const BorderSide(color: GrenierColors.primary),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
