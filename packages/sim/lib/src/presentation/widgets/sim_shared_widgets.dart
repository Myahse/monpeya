import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';

/// SIM Assurances UI kit — follows the Mon Peya design language: deep green
/// hero header, rounded white sheet, soft cards, animated progress.

const simLabelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: SimBrand.textDark,
);

BoxDecoration simCardDecoration({bool highlighted = false}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: highlighted ? SimBrand.primary : const Color(0xFFEDEFF1),
        width: highlighted ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (highlighted ? SimBrand.primary : Colors.black)
              .withValues(alpha: highlighted ? 0.14 : 0.04),
          blurRadius: highlighted ? 18 : 12,
          offset: const Offset(0, 6),
        ),
      ],
    );

Widget simCardSection({required String title, required List<Widget> children}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: simCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: SimBrand.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

// ── Header ─────────────────────────────────────────────────────────────────

/// Gradient hero: back, product, "Mes cartes", and animated step progress.
class SimHeroHeader extends StatelessWidget {
  const SimHeroHeader({
    super.key,
    required this.onBack,
    required this.productLabel,
    required this.steps,
    required this.current,
    this.onOpenCards,
  });

  final VoidCallback onBack;
  final String productLabel;
  final List<String> steps;
  final int current;
  final VoidCallback? onOpenCards;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(gradient: SimBrand.heroGradient),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -10,
            child: Icon(
              Icons.shield_rounded,
              size: 170,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    if (onOpenCards != null)
                      TextButton.icon(
                        onPressed: onOpenCards,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.credit_card_rounded, size: 18),
                        label: const Text(
                          'Mes cartes',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SimBrand.title.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Text(
                          productLabel,
                          key: ValueKey(productLabel),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SimProgress(steps: steps, current: current),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented progress bar with the current step's label.
class SimProgress extends StatelessWidget {
  const SimProgress({super.key, required this.steps, required this.current});

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
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        widthFactor: i <= current ? 1 : 0,
                        child: Container(height: 6, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Text(
            'Étape ${current + 1} sur ${steps.length} · ${steps[current]}',
            key: ValueKey(current),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Legacy compact header — kept for callers outside the main flow.
class SimHeader extends StatelessWidget {
  const SimHeader({super.key, required this.onBack, required this.productLabel, this.trailing});

  final VoidCallback onBack;
  final String productLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(tooltip: 'Retour', onPressed: onBack, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              productLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: SimBrand.textDark),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Legacy dot indicator — progress now lives in [SimHeroHeader].
class SimStepIndicator extends StatelessWidget {
  const SimStepIndicator({super.key, required this.steps, required this.current});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) => SimProgress(steps: steps, current: current);
}

/// Rounded content sheet that overlaps the hero header.
class SimSheet extends StatelessWidget {
  const SimSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: ColoredBox(color: SimBrand.background, child: child),
      ),
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────

class SimHeroCard extends StatelessWidget {
  const SimHeroCard({super.key, required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: SimBrand.heroGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: SimBrand.textDark)),
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

/// Large selectable card (product or formula).
class SimChoiceCard extends StatelessWidget {
  const SimChoiceCard({
    super.key,
    required this.selected,
    required this.title,
    required this.icon,
    this.subtitle,
    this.price,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final String? price;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: simCardDecoration(highlighted: selected),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? SimBrand.primary : SimBrand.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: selected ? Colors.white : SimBrand.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: SimBrand.textDark),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: SimBrand.muted)),
                ],
              ),
            ),
            if (price != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  price!,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: SimBrand.primary),
                ),
              ),
            AnimatedScale(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              scale: selected ? 1 : 0,
              child: const Icon(Icons.check_circle_rounded, color: SimBrand.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// − value + stepper.
class SimStepper extends StatelessWidget {
  const SimStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, int next, bool enabled) => IconButton.filledTonal(
          onPressed: enabled ? () => onChanged(next) : null,
          style: IconButton.styleFrom(
            backgroundColor: SimBrand.primary.withValues(alpha: 0.1),
            foregroundColor: SimBrand.primary,
          ),
          icon: Icon(icon),
        );

    return Row(
      children: [
        Expanded(child: Text(label, style: simLabelStyle)),
        button(Icons.remove_rounded, value - 1, value > min),
        SizedBox(
          width: 44,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text(
              '$value',
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: SimBrand.textDark),
            ),
          ),
        ),
        button(Icons.add_rounded, value + 1, value < max),
      ],
    );
  }
}

/// Shown when the partner catalogue can't be loaded (no key, offline…).
class SimUnavailableCard extends StatelessWidget {
  const SimUnavailableCard({super.key, required this.message, required this.onRetry});

  final String message;
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
            decoration: BoxDecoration(
              color: SimBrand.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded, color: SimBrand.primary, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'Catalogue indisponible',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: SimBrand.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SimBrand.muted, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: SimBrand.primary,
              side: const BorderSide(color: SimBrand.primary),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
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

/// Upload button showing picked state.
class SimUploadTile extends StatelessWidget {
  const SimUploadTile({
    super.key,
    required this.icon,
    required this.label,
    this.fileName,
    required this.onTap,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: done ? SimBrand.primary.withValues(alpha: 0.06) : SimBrand.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? SimBrand.primary : const Color(0xFFDDE1E4),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle_rounded : icon, color: SimBrand.primary),
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
              Icon(done ? Icons.edit_rounded : Icons.add_a_photo_outlined, color: SimBrand.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class SimResultCard extends StatelessWidget {
  const SimResultCard({super.key, required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: 0.92 + 0.08 * t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: SimBrand.heroGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: SimBrand.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(Icons.verified_user_rounded, size: 80, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: simCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 22, color: Color(0xFFEDEFF1)),
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

/// Floating primary button bar. Leaves room on the right for the host's
/// N'TERI bubble when it sits at its default spot above this bar.
class SimBottomBar extends StatelessWidget {
  const SimBottomBar({super.key, required this.label, required this.onPrimary, this.loading = false});

  final String label;
  final VoidCallback onPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading ? null : SimBrand.heroGradient,
          color: loading ? const Color(0xFFE5E7EB) : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPrimary,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 54,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: SimBrand.primary),
                        )
                      : Row(
                          key: ValueKey(label),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFE6D4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: SimBrand.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: SimBrand.primaryDark)),
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
