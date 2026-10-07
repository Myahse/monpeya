import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grenier/src/core/constants/grenier.brand.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';

abstract final class GrenierColors {
  static const primary = GrenierBrand.primary;
  static const dark = GrenierBrand.primaryDark;
  static const bg = Color(0xFFF7F8F7);
  static const card = Colors.white;
  static const text = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFEEF0EE);
  static const soft = Color(0xFFE8F3E9);
  static const upFg = Color(0xFFB45309);
  static const upBg = Color(0xFFFFF1E6);
  static const downFg = Color(0xFF1D4ED8);
  static const downBg = Color(0xFFE8F0FB);

  /// Placeholder tones for products without a photo.
  static const tones = [
    Color(0xFFE9DCC3),
    Color(0xFFF1D9A7),
    Color(0xFFD9C2C2),
    Color(0xFFE8C4B8),
    Color(0xFFDCE5C8),
    Color(0xFFD4DCCF),
  ];
}

BoxDecoration grenierCard({double radius = 18}) => BoxDecoration(
      color: GrenierColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: GrenierColors.border),
    );

// ── Motion ─────────────────────────────────────────────────────────────────

/// Fades and slides its child in once, after [delay].
class GrenierRise extends StatefulWidget {
  const GrenierRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 16),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<GrenierRise> createState() => _GrenierRiseState();
}

class _GrenierRiseState extends State<GrenierRise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: const Cubic(.2, .8, .2, 1));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: widget.offset * (1 - _t.value),
          child: child,
        ),
      ),
    );
  }
}

/// Shrinks slightly while pressed.
class GrenierPressable extends StatefulWidget {
  const GrenierPressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<GrenierPressable> createState() => _GrenierPressableState();
}

class _GrenierPressableState extends State<GrenierPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// White dot with an expanding halo — "prix en direct".
class GrenierLiveDot extends StatefulWidget {
  const GrenierLiveDot({super.key, this.color = Colors.white});

  final Color color;

  @override
  State<GrenierLiveDot> createState() => _GrenierLiveDotState();
}

class _GrenierLiveDotState extends State<GrenierLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + _c.value * 1.8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - _c.value) * 0.6),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
              child: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Layout ─────────────────────────────────────────────────────────────────

/// Green header + rounded light panel (same layout as Mr Immo).
class GrenierHeaderPage extends StatelessWidget {
  const GrenierHeaderPage({
    super.key,
    required this.header,
    required this.body,
  });

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: GrenierColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, top + 14, 20, 26),
              child: GrenierRise(child: header),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: ColoredBox(color: GrenierColors.bg, child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title block used in the green header.
class GrenierHeaderTitle extends StatelessWidget {
  const GrenierHeaderTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.live = false,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool live;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (live) ...[
                    const GrenierLiveDot(),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    eyebrow,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class GrenierNavItem {
  const GrenierNavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Floating pill tab bar with a sliding selector.
class GrenierPillNav extends StatelessWidget {
  const GrenierPillNav({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  final List<GrenierNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  static double clearance(BuildContext context) =>
      58 + 18 + MediaQuery.viewPaddingOf(context).bottom + 16;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottom),
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 58,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: index * w,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: GrenierColors.soft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => onSelected(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  i == index
                                      ? items[i].selectedIcon
                                      : items[i].icon,
                                  size: 20,
                                  color: i == index
                                      ? GrenierColors.primary
                                      : GrenierColors.muted,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  items[i].label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: i == index
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: i == index
                                        ? GrenierColors.primary
                                        : GrenierColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Products ───────────────────────────────────────────────────────────────

/// Product photo, or a tinted tile with the initial while the API has none.
class GrenierProductImage extends StatelessWidget {
  const GrenierProductImage({super.key, required this.product, this.big = false});

  final GrenierProduit product;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final tone = GrenierColors.tones[product.id.abs() % GrenierColors.tones.length];
    final fallback = ColoredBox(
      color: tone,
      child: Center(
        child: Text(
          product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: big ? 96 : 48,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
    final url = product.imageUrl;
    if (url == null) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

/// Price change versus the previous reading, as a small pill.
class GrenierChangePill extends StatelessWidget {
  const GrenierChangePill({super.key, required this.delta, this.suffix = ''});

  final double delta;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final flat = delta == 0;
    final label = flat
        ? 'Stable$suffix'
        : '${up ? '+' : '−'}${GrenierProduit.formatAmount(delta.abs())}$suffix';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: flat
            ? const Color(0xFFF1F2F4)
            : (up ? GrenierColors.upBg : GrenierColors.downBg),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: flat
              ? const Color(0xFF4B5563)
              : (up ? GrenierColors.upFg : GrenierColors.downFg),
        ),
      ),
    );
  }
}

/// Square product card: full photo, fade over the bottom quarter, name and
/// price. Highlights briefly when the price changes live.
class GrenierProductCard extends StatelessWidget {
  const GrenierProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.size = 140,
    this.flash = false,
  });

  final GrenierProduit product;
  final VoidCallback onTap;
  final double size;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    return GrenierPressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${product.name}, ${product.priceLabel} par ${product.unit}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: flash ? GrenierColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'grenier-product-${product.id}',
                  child: GrenierProductImage(product: product),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.25,
                    widthFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xB8000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: Text(
                          '${GrenierProduit.formatAmount(product.price)} F / ${product.unit}',
                          key: ValueKey(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
