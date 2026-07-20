import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/shared/widgets/billetterie_bottom_nav.widget.dart';

/// Shared pulse animation for Billetterie skeletons.
class BilletterieSkeletonPulse extends StatefulWidget {
  const BilletterieSkeletonPulse({super.key, required this.builder});

  final Widget Function(BuildContext context, Color Function(Color) shade)
      builder;

  @override
  State<BilletterieSkeletonPulse> createState() =>
      _BilletterieSkeletonPulseState();
}

class _BilletterieSkeletonPulseState extends State<BilletterieSkeletonPulse>
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
    this.radius = 10,
  });

  final double? width;
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

/// Home catalog loading skeleton (search + sections + ticket cards).
class BilletterieHomeSkeleton extends StatelessWidget {
  const BilletterieHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final bone = brand.border;
    final soft = brand.searchFill;

    return BilletterieSkeletonPulse(
      builder: (context, shade) {
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            BilletterieBottomNav.contentBottomPadding(context),
          ),
          children: [
            Center(child: _Bone(width: 180, height: 18, color: shade(bone))),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Bone(
                    width: double.infinity,
                    height: 48,
                    color: shade(soft),
                    radius: 28,
                  ),
                ),
                const SizedBox(width: 12),
                _Bone(width: 44, height: 44, color: shade(soft), radius: 12),
              ],
            ),
            const SizedBox(height: 24),
            _Bone(width: 120, height: 16, color: shade(bone)),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, _) => _Bone(
                  width: 110,
                  height: 72,
                  color: shade(soft),
                  radius: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _Bone(width: 90, height: 16, color: shade(bone)),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TicketCardBone(color: shade(soft), ink: shade(bone)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Mes tickets loading skeleton.
class BilletterieTicketsSkeleton extends StatelessWidget {
  const BilletterieTicketsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final bone = brand.border;
    final soft = brand.searchFill;

    return BilletterieSkeletonPulse(
      builder: (context, shade) {
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            BilletterieBottomNav.contentBottomPadding(context),
          ),
          children: [
            Center(child: _Bone(width: 120, height: 18, color: shade(bone))),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Bone(
                    width: double.infinity,
                    height: 48,
                    color: shade(soft),
                    radius: 28,
                  ),
                ),
                const SizedBox(width: 12),
                _Bone(width: 44, height: 44, color: shade(soft), radius: 12),
              ],
            ),
            const SizedBox(height: 24),
            _Bone(width: 70, height: 16, color: shade(bone)),
            const SizedBox(height: 12),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TicketCardBone(color: shade(soft), ink: shade(bone)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Profile tab loading skeleton.
class BilletterieProfileSkeleton extends StatelessWidget {
  const BilletterieProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final bone = brand.border;
    final soft = brand.searchFill;

    return BilletterieSkeletonPulse(
      builder: (context, shade) {
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            BilletterieBottomNav.contentBottomPadding(context) + 24,
          ),
          children: [
            Center(child: _Bone(width: 70, height: 18, color: shade(bone))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: shade(soft),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _Bone(width: 52, height: 52, color: shade(bone), radius: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bone(width: 140, height: 14, color: shade(bone)),
                        const SizedBox(height: 8),
                        _Bone(width: 100, height: 10, color: shade(bone)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Bone(
              width: double.infinity,
              height: 72,
              color: shade(soft),
              radius: 16,
            ),
            const SizedBox(height: 24),
            _Bone(width: 130, height: 14, color: shade(bone)),
            const SizedBox(height: 10),
            _Bone(
              width: double.infinity,
              height: 40,
              color: shade(soft),
              radius: 8,
            ),
            const SizedBox(height: 12),
            _Bone(
              width: double.infinity,
              height: 48,
              color: shade(soft),
              radius: 14,
            ),
            const SizedBox(height: 24),
            _Bone(width: 180, height: 14, color: shade(bone)),
            const SizedBox(height: 10),
            _Bone(
              width: double.infinity,
              height: 48,
              color: shade(soft),
              radius: 8,
            ),
            const SizedBox(height: 12),
            _Bone(
              width: double.infinity,
              height: 48,
              color: shade(soft),
              radius: 14,
            ),
          ],
        );
      },
    );
  }
}

class _TicketCardBone extends StatelessWidget {
  const _TicketCardBone({required this.color, required this.ink});

  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 0.48,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Bone(width: 56, height: 12, color: ink),
                const Spacer(),
                _Bone(width: 48, height: 12, color: ink),
              ],
            ),
            const Spacer(),
            _Bone(width: 120, height: 14, color: ink),
            const SizedBox(height: 8),
            _Bone(width: 80, height: 10, color: ink),
          ],
        ),
      ),
    );
  }
}
