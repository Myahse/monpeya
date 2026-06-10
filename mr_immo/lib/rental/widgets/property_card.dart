import 'package:flutter/material.dart';

import '../theme/rental_theme.dart';
import '../models/rental_property.dart';

/// 200×200 property card — mirrors RN `PropertyCard` in ListingsScreen.
class RentalPropertyCard extends StatelessWidget {
  const RentalPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
  });

  final RentalProperty property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (property.listingStatus) {
      'active' => const Color(0xFF10B981),
      'pending' => const Color(0xFF3B82F6),
      _ => const Color(0xFFF59E0B),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        margin: const EdgeInsets.only(right: RentalTheme.spacingLg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PropertyImage(url: property.imageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.favorite_border,
                color: const Color(0xFF666666),
                size: 22,
                shadows: const [Shadow(color: Colors.white, blurRadius: 1)],
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  property.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.formattedPrice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyImage extends StatelessWidget {
  const _PropertyImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFF5F5F5),
        child: Center(
          child: Icon(Icons.home_work_outlined, size: 48, color: RentalTheme.greenMid),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFF5F5F5),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: RentalTheme.greenMid),
        ),
      ),
    );
  }
}
