import 'package:flutter/material.dart';

class NteriNewsCarousel extends StatelessWidget {
  const NteriNewsCarousel({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    const cardRadius = 16.0;
    const cardGap = 12.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <({String title, String subtitle, String imageAsset, String badge})>[
      (
        title: 'TukShopp Campus Connect',
        subtitle: 'Événement • Jeux • Cadeaux • Open stage',
        imageAsset: 'assets/images/ad-1.jpg',
        badge: 'Événement',
      ),
      (
        title: 'Essence Academy',
        subtitle: 'Formations • Figma • Canva',
        imageAsset: 'assets/images/ad-2.jpg',
        badge: 'Formation',
      ),
      (
        title: 'GEN Z FEST',
        subtitle: 'Hangout • Music • Games • Network',
        imageAsset: 'assets/images/ad-1.jpg',
        badge: 'Festival',
      ),
      (
        title: 'Exploration 2026',
        subtitle: 'Conférence • Youth Festival',
        imageAsset: 'assets/images/ad-2.jpg',
        badge: 'Conférence',
      ),
    ];

    final screenW = MediaQuery.sizeOf(context).width;
    // Reduce width a bit vs full-bleed.
    const sideInset = 24.0;
    final containerW = (screenW - sideInset * 2).clamp(0.0, screenW).toDouble();

    // Full-bleed + centered: expand beyond page padding equally on both sides.
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: height,
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: 0,
          maxWidth: containerW,
          minHeight: height,
          maxHeight: height,
          child: SizedBox(
            width: containerW,
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(cardRadius),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                        child: PageView.builder(
                      itemCount: items.length,
                      padEnds: false,
                      controller: PageController(viewportFraction: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : cardGap),
                          child: SizedBox(
                            width: cardWidth,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  item.imageAsset,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                // Bottom fade like RN LinearGradient
                                const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0x00000000), Color(0x8C000000)],
                                        stops: [0.35, 1.0],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: SizedBox(height: 86, width: double.infinity),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.30),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item.badge.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        style: const TextStyle(
                                          color: Color(0xE6FFFFFF),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                      ),
                    ),
                    if (isDark)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(cardRadius),
                              border: Border.all(color: Colors.white, width: 0.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

