import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';

/// SIM Assurances UI kit — in SIM's own colours ([SimBrand]), with short,
/// smooth motion: entrances, pulsing shield, animated selection and totals.

const simLabelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SimBrand.textDark);

BoxDecoration simCardDecoration({bool selected = false, double radius = 20}) => BoxDecoration(
      color: selected ? SimBrand.soft : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: selected ? SimBrand.primary : SimBrand.border, width: selected ? 2 : 1),
    );

Widget simCardSection({required String title, required List<Widget> children}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: simCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: SimBrand.textDark),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

// ── Motion ─────────────────────────────────────────────────────────────────

/// Fades and slides its child in once, after [delay].
class SimRise extends StatefulWidget {
  const SimRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 22),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<SimRise> createState() => _SimRiseState();
}

class _SimRiseState extends State<SimRise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: const Cubic(.2, .8, .2, 1));

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
        child: Transform.translate(offset: widget.offset * (1 - _t.value), child: child),
      ),
    );
  }
}

/// Shrinks slightly while pressed.
class SimPressable extends StatefulWidget {
  const SimPressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<SimPressable> createState() => _SimPressableState();
}

class _SimPressableState extends State<SimPressable> {
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
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        child: widget.child,
      ),
    );
  }
}

/// White shield floating gently, with rings pulsing outwards.
class SimShieldHero extends StatefulWidget {
  const SimShieldHero({super.key});

  @override
  State<SimShieldHero> createState() => _SimShieldHeroState();
}

class _SimShieldHeroState extends State<SimShieldHero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
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
      width: 240,
      height: 200,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final float = Curves.easeInOut.transform(t < .5 ? t * 2 : (1 - t) * 2);
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final shift in const [0.0, 1 / 3, 2 / 3])
                Builder(builder: (context) {
                  final p = (t + shift) % 1;
                  return Opacity(
                    opacity: (1 - p) * 0.55,
                    child: Container(
                      width: 92 + 150 * p,
                      height: 92 + 150 * p,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  );
                }),
              Transform.translate(
                offset: Offset(0, -6 * float),
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, 18)),
                    ],
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: SimBrand.primary, size: 46),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Check mark that pops in and draws itself.
class SimCheckBurst extends StatelessWidget {
  const SimCheckBurst({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, t, _) {
        final pop = Curves.easeOutBack.transform((t / 0.6).clamp(0, 1));
        final draw = Curves.easeOut.transform(((t - 0.45) / 0.55).clamp(0, 1));
        return Transform.scale(
          scale: 0.4 + 0.6 * pop,
          child: Opacity(
            opacity: pop.clamp(0, 1),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: SimBrand.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: SimBrand.primary.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 14)),
                ],
              ),
              child: CustomPaint(painter: _CheckPainter(draw)),
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.29, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.37);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

// ── Brand ──────────────────────────────────────────────────────────────────

/// SIM logo when provided, else the name in a white badge.
class SimLogoBadge extends StatelessWidget {
  const SimLogoBadge({super.key, this.height = 34});

  final double height;

  @override
  Widget build(BuildContext context) {
    final asset = SimBrand.logoAsset;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
      ),
      child: asset != null
          ? Image.asset(asset, height: height - 10, fit: BoxFit.contain)
          : const Text(
              'SIM ASSURANCES',
              style: TextStyle(color: SimBrand.primary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .6),
            ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

/// Brand header for the subscription steps: back, product, segmented
/// progress that fills as the user advances.
class SimHeader extends StatelessWidget {
  const SimHeader({
    super.key,
    required this.onBack,
    required this.productLabel,
    this.trailing,
    this.steps = const [],
    this.current = 0,
  });

  final VoidCallback onBack;
  final String productLabel;
  final Widget? trailing;
  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: SimBrand.primary,
      padding: EdgeInsets.fromLTRB(8, top + 4, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SimBrand.title.toUpperCase(),
                      style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .6),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        productLabel,
                        key: ValueKey(productLabel),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SimStepIndicator(steps: steps, current: current),
            ),
          ],
        ],
      ),
    );
  }
}

/// Segmented white progress bar + "Étape n sur N".
class SimStepIndicator extends StatelessWidget {
  const SimStepIndicator({super.key, required this.steps, required this.current});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(height: 5, color: Colors.white.withValues(alpha: .28)),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        widthFactor: i <= current ? 1 : 0,
                        child: Container(height: 5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            'Étape ${current + 1} sur ${steps.length} · ${steps[current.clamp(0, steps.length - 1)]}',
            key: ValueKey(current),
            style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Rounded light panel overlapping the brand header.
class SimSheet extends StatelessWidget {
  const SimSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -26),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: ColoredBox(color: SimBrand.background, child: child),
      ),
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────

/// Step title with a short explanation.
class SimHeroCard extends StatelessWidget {
  const SimHeroCard({super.key, required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: SimBrand.soft, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: SimBrand.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: SimBrand.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: SimBrand.muted, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Large selectable card with an animated radio dot.
class SimChoiceCard extends StatelessWidget {
  const SimChoiceCard({
    super.key,
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final String? trailing;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SimPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(14),
          decoration: simCardDecoration(selected: selected, radius: 18),
          child: Row(
            children: [
              if (icon != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? SimBrand.primary : SimBrand.soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: selected ? Colors.white : SimBrand.primary),
                ),
              ] else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? SimBrand.primary : const Color(0xFFC3CAD6), width: 2),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: SimBrand.primary),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SimBrand.textDark)),
                    if (subtitle != null)
                      Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: SimBrand.muted)),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: SimBrand.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Durée" row with − value + buttons.
class SimStepper extends StatelessWidget {
  const SimStepper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, String semantic, int next, bool on) => Semantics(
          button: true,
          label: semantic,
          child: SimPressable(
            onTap: on ? () => onChanged(next) : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: on ? 1 : .4,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SimBrand.soft, borderRadius: BorderRadius.circular(14)),
                child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SimBrand.primary)),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: simCardDecoration(radius: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: SimBrand.muted)),
              ],
            ),
          ),
          btn('−', 'Diminuer', value - 1, value > min),
          SizedBox(
            width: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          btn('+', 'Augmenter', value + 1, value < max),
        ],
      ),
    );
  }
}

class SimField extends StatelessWidget {
  const SimField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboard,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: simLabelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: keyboard == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: SimBrand.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SimBrand.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Upload button that shows when a photo has been added.
class SimUploadTile extends StatelessWidget {
  const SimUploadTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.fileName,
  });

  final IconData icon;
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = fileName != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SimPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: done ? SimBrand.soft : SimBrand.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: done ? SimBrand.primary : const Color(0xFFD5DCE8)),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(done ? Icons.check_circle_rounded : icon, key: ValueKey(done), color: SimBrand.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: SimBrand.textDark)),
                    Text(
                      fileName ?? 'Touchez pour ajouter une photo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: SimBrand.muted),
                    ),
                  ],
                ),
              ),
              Icon(done ? Icons.edit_outlined : Icons.add_a_photo_outlined, color: SimBrand.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand card for an amount; scales in when it appears.
class SimResultCard extends StatelessWidget {
  const SimResultCard({super.key, required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: 0.92 + 0.08 * t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SimBrand.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: SimBrand.primary.withValues(alpha: .3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class SimSummaryCard extends StatelessWidget {
  const SimSummaryCard({super.key, required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: simCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: Color(0xFFEDEFF3)),
            Row(
              children: [
                Expanded(child: Text(rows[i].$1, style: const TextStyle(color: SimBrand.muted, fontSize: 13))),
                Text(rows[i].$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: SimBrand.textDark)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SimPaymentTile extends StatelessWidget {
  const SimPaymentTile({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SimChoiceCard(
      selected: selected,
      title: title,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap ?? () {},
    );
  }
}

/// Bottom panel: optional amount (animated) above the primary button.
/// Slides up the first time it appears.
class SimBottomBar extends StatelessWidget {
  const SimBottomBar({
    super.key,
    required this.label,
    required this.onPrimary,
    this.loading = false,
    this.amountLabel,
    this.amount,
    this.footnote,
  });

  final String label;
  final VoidCallback onPrimary;
  final bool loading;
  final String? amountLabel;
  final String? amount;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => FractionalTranslation(translation: Offset(0, t), child: child),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [BoxShadow(color: SimBrand.primary.withValues(alpha: .12), blurRadius: 30, offset: const Offset(0, -12))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (amount != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(amountLabel ?? 'Prime', style: const TextStyle(fontSize: 13, color: SimBrand.muted, fontWeight: FontWeight.w600)),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (c, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, .35), end: Offset.zero).animate(a),
                              child: c,
                            ),
                          ),
                          child: Text(
                            amount!,
                            key: ValueKey(amount),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: SimBrand.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (footnote != null)
                    Text(footnote!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: SimBrand.muted)),
                ],
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: loading ? null : onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: SimBrand.primary,
                  disabledBackgroundColor: SimBrand.soft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? Row(
                          key: const ValueKey('loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: SimBrand.primary),
                            ),
                            const SizedBox(width: 10),
                            Text(label, style: const TextStyle(color: SimBrand.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                          ],
                        )
                      : Row(
                          key: ValueKey(label),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
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

class SimSuccessBanner extends StatelessWidget {
  const SimSuccessBanner({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SimBrand.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SimBrand.primary.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: SimBrand.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: SimBrand.primaryDark)),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(fontSize: 12.5, color: SimBrand.primaryDark, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
