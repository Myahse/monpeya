import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:app/src/core/api/models/mon_peya_subscription.models.dart';
import 'package:app/src/features/subscriptions/presentation/widgets/subscription_plan_card.widget.dart';

/// Theme-adaptive subscribe paywall (yearly / monthly side-by-side cards).
class SubscriptionPaywall extends StatelessWidget {
  const SubscriptionPaywall({
    super.key,
    required this.plans,
    required this.selectedPlanCode,
    required this.onSelectPlan,
    required this.onSubscribe,
    required this.subscribeLabel,
    this.onMaybeLater,
    this.maybeLaterLabel = 'Plus tard',
    this.showBackButton = true,
    this.headline = 'Abonnez-vous',
    this.subtitle = 'Accès illimité.\nTous vos services Mon Peya.',
    this.footnote =
        'Les créateurs et partenaires reçoivent la majorité de votre abonnement.',
    this.loading = false,
    this.subscribeEnabled = true,
    this.banner,
    this.activeBanner,
    this.extra,
    this.bottomInset = 0,
  });

  final List<MonPeyaPlan> plans;
  final String? selectedPlanCode;
  final ValueChanged<String> onSelectPlan;
  final VoidCallback? onSubscribe;
  final VoidCallback? onMaybeLater;
  final String maybeLaterLabel;
  final bool showBackButton;
  final String subscribeLabel;
  final String headline;
  final String subtitle;
  final String footnote;
  final bool loading;
  final bool subscribeEnabled;
  final Widget? banner;
  final Widget? activeBanner;
  final Widget? extra;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final top = MediaQuery.viewPaddingOf(context).top;
    final bottom = MediaQuery.viewPaddingOf(context).bottom + bottomInset;
    final displayPlans = _plansForPaywall(plans);
    final discount = _yearlyDiscountPercent(displayPlans);

    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    final ctaBg = isDark ? Colors.white : cs.primary;
    final ctaFg = isDark ? Colors.black : cs.onPrimary;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _PaywallAtmosphere(isDark: isDark, brand: cs.primary),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.92),
                      ]
                    : [
                        cs.surface.withValues(alpha: 0.15),
                        cs.surface.withValues(alpha: 0.72),
                        cs.surface,
                      ],
                stops: const [0.0, 0.42, 0.78],
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: top + (showBackButton ? 4 : 16)),
                if (showBackButton)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onMaybeLater,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: ink,
                        size: 32,
                      ),
                    ),
                  ),
                Expanded(
                  child: loading
                      ? Center(child: CircularProgressIndicator(color: cs.primary))
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(22, 8, 22, 16 + bottom),
                          child: Column(
                            children: [
                              SizedBox(height: showBackButton ? 28 : 40),
                              Text(
                                headline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink.withValues(alpha: 0.9),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                footnote,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              if (activeBanner != null) ...[
                                const SizedBox(height: 18),
                                activeBanner!,
                              ],
                              if (banner != null) ...[
                                const SizedBox(height: 14),
                                banner!,
                              ],
                              const SizedBox(height: 36),
                              if (displayPlans.isEmpty)
                                Text(
                                  'Aucune formule disponible pour le moment.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0;
                                        i < displayPlans.length;
                                        i++) ...[
                                      if (i > 0) const SizedBox(width: 12),
                                      Expanded(
                                        child: _PaywallPlanCard(
                                          plan: displayPlans[i],
                                          selected: displayPlans[i].code ==
                                              selectedPlanCode,
                                          badge: displayPlans[i]
                                                      .billingPeriod
                                                      .toUpperCase() ==
                                                  'YEARLY' &&
                                              discount != null
                                              ? '$discount% OFF'
                                              : null,
                                          sibling: displayPlans.length == 2
                                              ? displayPlans[1 - i]
                                              : null,
                                          onTap: () => onSelectPlan(
                                            displayPlans[i].code,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: FilledButton(
                                  onPressed:
                                      subscribeEnabled ? onSubscribe : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ctaBg,
                                    foregroundColor: ctaFg,
                                    disabledBackgroundColor:
                                        ctaBg.withValues(alpha: 0.35),
                                    disabledForegroundColor:
                                        ctaFg.withValues(alpha: 0.45),
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    subscribeLabel,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              if (onMaybeLater != null) ...[
                                const SizedBox(height: 14),
                                TextButton(
                                  onPressed: onMaybeLater,
                                  child: Text(
                                    maybeLaterLabel,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              if (extra != null) ...[
                                const SizedBox(height: 10),
                                extra!,
                              ],
                              const SizedBox(height: 18),
                              Text(
                                'Renouvellement automatique.\n'
                                'Annulez à tout moment avant chaque échéance.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted.withValues(alpha: 0.85),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Prefer YEARLY + MONTHLY side by side; otherwise first two / one.
  static List<MonPeyaPlan> _plansForPaywall(List<MonPeyaPlan> plans) {
    if (plans.isEmpty) return const [];
    final yearly = plans
        .where((p) => p.billingPeriod.toUpperCase() == 'YEARLY')
        .firstOrNull;
    final monthly = plans
        .where((p) => p.billingPeriod.toUpperCase() == 'MONTHLY')
        .firstOrNull;
    if (yearly != null && monthly != null) return [yearly, monthly];
    if (plans.length == 1) return plans;
    return plans.take(2).toList();
  }

  static int? _yearlyDiscountPercent(List<MonPeyaPlan> plans) {
    final yearly = plans
        .where((p) => p.billingPeriod.toUpperCase() == 'YEARLY')
        .firstOrNull;
    final monthly = plans
        .where((p) => p.billingPeriod.toUpperCase() == 'MONTHLY')
        .firstOrNull;
    if (yearly == null || monthly == null || monthly.price <= 0) return null;
    final fullYear = monthly.price * 12;
    if (fullYear <= yearly.price) return null;
    final pct = (((fullYear - yearly.price) / fullYear) * 100).round();
    return pct > 0 ? pct : null;
  }
}

class _PaywallPlanCard extends StatelessWidget {
  const _PaywallPlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.badge,
    this.sibling,
  });

  final MonPeyaPlan plan;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final MonPeyaPlan? sibling;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final period = plan.billingPeriod.toUpperCase();
    final primary = _primaryPrice(plan);
    final secondary = _secondaryPrice(plan, sibling);

    final border = selected
        ? (isDark ? Colors.white : cs.primary)
        : cs.outline.withValues(alpha: isDark ? 0.45 : 0.55);
    final fill = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : cs.surface.withValues(alpha: 0.72);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  primary,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    secondary,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(
                        alpha: period == 'YEARLY' ? 0.95 : 0.8,
                      ),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -11,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : cs.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: isDark ? Colors.black : cs.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatMoney(num amount, String currency) {
    final whole = amount.round();
    final digits = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('\u202f');
    }
    return '$buf $currency';
  }

  static String _primaryPrice(MonPeyaPlan plan) {
    final period = SubscriptionPlanCard.billingPeriodLabel(plan.billingPeriod);
    return '${_formatMoney(plan.price, plan.currency)}/$period';
  }

  static String? _secondaryPrice(MonPeyaPlan plan, MonPeyaPlan? sibling) {
    final period = plan.billingPeriod.toUpperCase();
    if (period == 'YEARLY') {
      final monthly = plan.price / 12;
      return '(${_formatMoney(monthly, plan.currency)}/mois)';
    }
    if (period == 'MONTHLY' && sibling != null) {
      final yearlyEquiv = plan.price * 12;
      return '(${_formatMoney(yearlyEquiv, plan.currency)}/an)';
    }
    if (period == 'MONTHLY') {
      return '(${_formatMoney(plan.price * 12, plan.currency)}/an)';
    }
    return null;
  }
}

class _PaywallAtmosphere extends StatelessWidget {
  const _PaywallAtmosphere({
    required this.isDark,
    required this.brand,
  });

  final bool isDark;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EmberPainter(isDark: isDark, brand: brand),
      child: const SizedBox.expand(),
    );
  }
}

class _EmberPainter extends CustomPainter {
  _EmberPainter({required this.isDark, required this.brand});

  final bool isDark;
  final Color brand;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()..color = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF4F7F6),
    );

    final ember = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.55, size.height * 0.28),
        size.shortestSide * 0.85,
        isDark
            ? const [
                Color(0xCCB45309),
                Color(0x667C2D12),
                Color(0x00000000),
              ]
            : [
                const Color(0x66D97706),
                brand.withValues(alpha: 0.18),
                const Color(0x00000000),
              ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, ember);

    final green = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.15, size.height * 0.15),
        size.shortestSide * 0.7,
        [
          brand.withValues(alpha: isDark ? 0.4 : 0.22),
          const Color(0x00000000),
        ],
      );
    canvas.drawRect(rect, green);

    final rnd = math.Random(7);
    final spark = Paint()..style = PaintingStyle.fill;
    final sparkCount = isDark ? 55 : 28;
    for (var i = 0; i < sparkCount; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.72;
      final r = 0.6 + rnd.nextDouble() * (isDark ? 2.4 : 1.8);
      final a = (isDark ? 0.15 : 0.08) + rnd.nextDouble() * (isDark ? 0.55 : 0.22);
      spark.color = Color.fromRGBO(
        isDark ? 255 : 180,
        140 + rnd.nextInt(80),
        40 + rnd.nextInt(40),
        a,
      );
      canvas.drawCircle(Offset(x, y), r, spark);
    }

    final bottom = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.45),
        Offset(0, size.height),
        [
          const Color(0x00000000),
          isDark ? const Color(0xFF000000) : const Color(0xFFF4F7F6),
        ],
      );
    canvas.drawRect(rect, bottom);
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.brand != brand;
}
