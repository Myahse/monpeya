import 'package:flutter/material.dart';

/// Shared pulse animation for PeyaPay inline skeletons.
class PeyapaySkeletonPulse extends StatefulWidget {
  const PeyapaySkeletonPulse({super.key, required this.builder});

  final Widget Function(BuildContext context, Color Function(Color) shade) builder;

  @override
  State<PeyapaySkeletonPulse> createState() => _PeyapaySkeletonPulseState();
}

class _PeyapaySkeletonPulseState extends State<PeyapaySkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = 0.55 + (_pulse.value * 0.45);
        Color shade(Color base) => base.withValues(alpha: t);
        return widget.builder(context, shade);
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 8,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder for the welcome name in the top bar.
class PeyapayNameSkeleton extends StatelessWidget {
  const PeyapayNameSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xFFE8ECF0);

    return PeyapaySkeletonPulse(
      builder: (context, shade) => _Bone(
        width: 148,
        height: 16,
        color: shade(bone),
        radius: 8,
      ),
    );
  }
}

/// Placeholder for the balance amount inside the green card.
class PeyapayBalanceSkeleton extends StatelessWidget {
  const PeyapayBalanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return PeyapaySkeletonPulse(
      builder: (context, shade) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(
            width: 88,
            height: 12,
            color: shade(Colors.white.withValues(alpha: 0.28)),
            radius: 6,
          ),
          const SizedBox(height: 10),
          _Bone(
            width: 180,
            height: 28,
            color: shade(Colors.white.withValues(alpha: 0.35)),
            radius: 8,
          ),
        ],
      ),
    );
  }
}

/// Placeholder rows for recent transactions history.
class PeyapayTransactionsSkeleton extends StatelessWidget {
  const PeyapayTransactionsSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final bone = isDark ? cs.surfaceContainerHighest : const Color(0xFFE8ECF0);
    final boneSoft = isDark ? cs.surfaceContainerHigh : const Color(0xFFF3F5F7);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);

    return PeyapaySkeletonPulse(
      builder: (context, shade) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              margin: EdgeInsets.only(bottom: i == count - 1 ? 0 : 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  _Bone(width: 42, height: 42, color: shade(boneSoft), radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bone(width: 140, height: 12, color: shade(bone), radius: 6),
                        const SizedBox(height: 8),
                        _Bone(width: 90, height: 10, color: shade(bone), radius: 5),
                      ],
                    ),
                  ),
                  _Bone(width: 72, height: 12, color: shade(bone), radius: 6),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
