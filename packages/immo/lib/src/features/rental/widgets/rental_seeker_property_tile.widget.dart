import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

/// Full-width property row for seeker browse lists.
class RentalSeekerPropertyTile extends StatelessWidget {
  const RentalSeekerPropertyTile({
    super.key,
    required this.property,
    required this.onTap,
  });

  final RentalProperty property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RentalTheme.spacingLg,
        0,
        RentalTheme.spacingLg,
        RentalTheme.spacingMd,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: _Thumb(url: property.imageUrl),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: RentalTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: RentalTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _locationLine(property),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: RentalTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      if (property.propertyType.isNotEmpty && property.propertyType != '—') ...[
                        const SizedBox(height: 4),
                        Text(
                          property.propertyType,
                          style: const TextStyle(fontSize: 12, color: RentalTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            property.formattedPrice,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: RentalTheme.greenMid,
                            ),
                          ),
                          if (property.surface > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${property.surface.toStringAsFixed(0)} m²',
                              style: const TextStyle(fontSize: 12, color: RentalTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _locationLine(RentalProperty property) {
    final parts = <String>[
      if (property.city.isNotEmpty) property.city,
      if (property.address.isNotEmpty) property.address,
      if (property.country.isNotEmpty) property.country,
    ];
    return parts.isEmpty ? '—' : parts.join(' • ');
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFF5F5F5),
        child: Center(
          child: Icon(Icons.home_work_outlined, color: RentalTheme.greenMid, size: 36),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFF5F5F5),
        child: Center(child: Icon(Icons.broken_image_outlined, color: RentalTheme.greenMid)),
      ),
    );
  }
}
