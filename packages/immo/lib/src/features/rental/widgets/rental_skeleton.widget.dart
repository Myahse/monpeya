import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

/// Shared pulse animation for Mr Immo Location skeletons.
class RentalSkeletonPulse extends StatefulWidget {
  const RentalSkeletonPulse({super.key, required this.builder});

  final Widget Function(BuildContext context, Color Function(Color) shade)
      builder;

  @override
  State<RentalSkeletonPulse> createState() => _RentalSkeletonPulseState();
}

class _RentalSkeletonPulseState extends State<RentalSkeletonPulse>
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
    required this.height,
    required this.color,
    this.width,
    this.radius = 12,
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

/// Square property card placeholder (home rows / favorites grid).
class RentalPropertyCardSkeleton extends StatelessWidget {
  const RentalPropertyCardSkeleton({
    super.key,
    required this.size,
    required this.color,
    required this.soft,
    this.margin = const EdgeInsets.only(right: 10),
  });

  final double size;
  final Color color;
  final Color soft;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: ColoredBox(color: color.withValues(alpha: 0.55)),
          ),
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: size * 0.7, height: 12, color: color, radius: 6),
                  const SizedBox(height: 6),
                  _Bone(width: size * 0.45, height: 10, color: color, radius: 6),
                  const Spacer(),
                  _Bone(width: size * 0.55, height: 12, color: color, radius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Home seeker listings body skeleton (two horizontal card rows).
class RentalHomeListingsSkeleton extends StatelessWidget {
  const RentalHomeListingsSkeleton({super.key, this.sections = 2});

  final int sections;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final bone = b.border;
    final soft = b.searchFill;

    return RentalSkeletonPulse(
      builder: (context, shade) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var s = 0; s < sections; s++) ...[
              if (s > 0) const SizedBox(height: RentalTheme.spacingXl),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RentalTheme.spacingLg,
                ),
                child: Row(
                  children: [
                    _Bone(
                      width: s == 0 ? 110 : 100,
                      height: 16,
                      color: shade(bone),
                    ),
                    const Spacer(),
                    _Bone(width: 56, height: 14, color: shade(bone)),
                  ],
                ),
              ),
              const SizedBox(height: RentalTheme.spacingMd),
              SizedBox(
                height: 192,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: RentalTheme.spacingLg,
                  ),
                  itemCount: 3,
                  itemBuilder: (_, __) => RentalPropertyCardSkeleton(
                    size: 192,
                    color: shade(bone),
                    soft: shade(soft),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Favorites tab grid skeleton.
class RentalFavoritesSkeleton extends StatelessWidget {
  const RentalFavoritesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final bone = b.border;
    final soft = b.searchFill;
    final cell =
        (MediaQuery.sizeOf(context).width - RentalTheme.spacingLg * 2 - 10) / 2;

    return RentalSkeletonPulse(
      builder: (context, shade) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            6,
            (_) => RentalPropertyCardSkeleton(
              size: cell,
              color: shade(bone),
              soft: shade(soft),
              margin: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen property detail skeleton (hero + sheet).
class RentalPropertyDetailSkeleton extends StatelessWidget {
  const RentalPropertyDetailSkeleton({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final bone = b.border;
    final soft = b.searchFill;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: b.bg,
        body: RentalSkeletonPulse(
          builder: (context, shade) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 280 + top,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: shade(RentalTheme.green.withValues(alpha: 0.35))),
                      Positioned(
                        top: top + 8,
                        left: 8,
                        child: Material(
                          color: Colors.black26,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: shade(RentalTheme.green),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          alignment: Alignment.topLeft,
                          child: _Bone(
                            width: 140,
                            height: 14,
                            color: Colors.white.withValues(alpha: 0.45),
                            radius: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      decoration: BoxDecoration(
                        color: b.card,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Bone(
                                      width: double.infinity,
                                      height: 28,
                                      color: shade(bone),
                                      radius: 8,
                                    ),
                                    const SizedBox(height: 10),
                                    _Bone(
                                      width: 80,
                                      height: 14,
                                      color: shade(bone),
                                      radius: 6,
                                    ),
                                    const SizedBox(height: 12),
                                    _Bone(
                                      width: 140,
                                      height: 20,
                                      color: shade(bone),
                                      radius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              _Bone(
                                width: 72,
                                height: 40,
                                color: shade(soft),
                                radius: 12,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _Bone(
                            width: 120,
                            height: 36,
                            color: shade(soft),
                            radius: 20,
                          ),
                          const SizedBox(height: 18),
                          _Bone(
                            width: double.infinity,
                            height: 52,
                            color: shade(RentalTheme.green.withValues(alpha: 0.35)),
                            radius: 16,
                          ),
                          const SizedBox(height: 12),
                          _Bone(
                            width: double.infinity,
                            height: 52,
                            color: shade(soft),
                            radius: 16,
                          ),
                          const SizedBox(height: 22),
                          _Bone(
                            width: double.infinity,
                            height: 1,
                            color: shade(bone),
                            radius: 1,
                          ),
                          const SizedBox(height: 16),
                          _Bone(
                            width: 180,
                            height: 14,
                            color: shade(bone),
                            radius: 6,
                          ),
                          const SizedBox(height: 12),
                          _Bone(
                            width: double.infinity,
                            height: 160,
                            color: shade(soft),
                            radius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
