import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grenier/src/presentation/widgets/grenier_price_chart.dart';
import 'package:grenier/src/presentation/widgets/grenier_ui.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';

/// Product detail: photo (shared with the card), price, chart and the same
/// product in other markets.
class GrenierDetailScreen extends StatefulWidget {
  const GrenierDetailScreen({
    super.key,
    required this.product,
    required this.history,
    required this.otherMarkets,
    required this.followed,
    required this.onToggleFollow,
  });

  final GrenierProduit product;
  final List<GrenierPricePoint> history;
  final List<GrenierProduit> otherMarkets;
  final bool followed;
  final ValueChanged<bool> onToggleFollow;

  @override
  State<GrenierDetailScreen> createState() => _GrenierDetailScreenState();
}

class _GrenierDetailScreenState extends State<GrenierDetailScreen> {
  late bool _followed = widget.followed;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _followed = !_followed);
    widget.onToggleFollow(_followed);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: GrenierColors.dark,
          content: Text(_followed ? 'Produit suivi' : 'Produit retiré de vos suivis'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final top = MediaQuery.paddingOf(context).top;
    final h = widget.history;
    final delta = h.length >= 2 ? h.last.price - h[h.length - 2].price : null;
    final all = [p, ...widget.otherMarkets];
    final cheapest = all.length > 1 ? all.reduce((a, b) => a.price <= b.price ? a : b).id : null;
    final updated = p.updatedAt?.toLocal();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: GrenierColors.bg,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 330 + top * 0.3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'grenier-product-${p.id}',
                    child: GrenierProductImage(product: p, big: true),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.25,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0x99000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.only(top: 300 + top * 0.3),
                children: [
                  Container(
                    constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 300),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                    decoration: const BoxDecoration(
                      color: GrenierColors.bg,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GrenierRise(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  if (p.market != null) 'Marché ${p.market}',
                                  if (updated != null)
                                    'mis à jour à ${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}',
                                ].join(' · '),
                                style: const TextStyle(fontSize: 13, color: GrenierColors.muted, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(p.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    '${GrenierProduit.formatAmount(p.price)} F',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: GrenierColors.primary),
                                  ),
                                  Text('le ${p.unit}', style: const TextStyle(fontSize: 14, color: GrenierColors.muted)),
                                  if (delta != null) GrenierChangePill(delta: delta, suffix: delta == 0 ? '' : ' F'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GrenierRise(
                          delay: const Duration(milliseconds: 100),
                          child: GrenierPriceChart(points: widget.history),
                        ),
                        if (widget.otherMarkets.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const GrenierRise(
                            delay: Duration(milliseconds: 180),
                            child: Text(
                              'Dans les autres marchés',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final (i, o) in widget.otherMarkets.indexed)
                            GrenierRise(
                              delay: Duration(milliseconds: 220 + i * 60),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: grenierCard(radius: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        o.market ?? 'Autre marché',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                    ),
                                    if (o.id == cheapest)
                                      Container(
                                        margin: const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: GrenierColors.soft,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Moins cher',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: GrenierColors.dark),
                                        ),
                                      ),
                                    Text(
                                      '${GrenierProduit.formatAmount(o.price)} F',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: top + 8,
              left: 16,
              child: _RoundButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: 'Retour',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              top: top + 8,
              right: 16,
              child: _RoundButton(
                icon: _followed ? Icons.star_rounded : Icons.star_outline_rounded,
                label: _followed ? 'Ne plus suivre' : 'Suivre ce produit',
                color: GrenierColors.primary,
                onTap: _toggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = GrenierColors.text,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GrenierPressable(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(icon, key: ValueKey(icon), color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
