import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';

/// Compact square property card with a thin black stroke.
class RentalPropertyCard extends StatelessWidget {
  const RentalPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.showFavorite = true,
    this.size = 192,
    this.margin = const EdgeInsets.only(right: 10),
  });

  final RentalProperty property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool showFavorite;

  /// Outer square side length.
  final double size;
  final EdgeInsetsGeometry? margin;

  static const cardRadius = 14.0;
  static const strokeWidth = 0.5;
  static const strokeColor = Colors.black;

  String get _locationLabel {
    final city = property.city.trim();
    final address = property.address.trim();
    if (city.isEmpty) return address;
    if (address.isEmpty) return city;
    final short = address.split(',').first.trim();
    if (short.isEmpty || short.toLowerCase() == city.toLowerCase()) {
      return city;
    }
    return '$city, $short';
  }

  String get _priceLabel {
    if (property.price <= 0) return '—';
    final formatted = property.price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$formatted Fcfa';
  }

  double get _rating {
    final r = property.rating;
    if (r <= 0) return 0;
    return r.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final innerRadius = cardRadius - strokeWidth;

    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: strokeColor, width: strokeWidth),
      ),
      child: Material(
        color: b.card,
        elevation: 0,
        borderRadius: BorderRadius.circular(innerRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PropertyImage(url: property.imageUrl),
                    if (showFavorite)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _FavoriteButton(
                          isFavorite: isFavorite,
                          onTap: onFavoriteTap,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              property.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: b.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _RatingBlock(rating: _rating, color: b.text),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _locationLabel.isEmpty ? '—' : _locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: b.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: b.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
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
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, this.onTap});

  final bool isFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 22,
          height: 22,
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? const Color(0xFFFF5A5F) : Colors.white,
            size: 12,
          ),
        ),
      ),
    );
  }
}

class _RatingBlock extends StatelessWidget {
  const _RatingBlock({required this.rating, required this.color});

  final double rating;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final threshold = i + 1;
            final IconData icon;
            if (rating >= threshold) {
              icon = Icons.star_rounded;
            } else if (rating >= threshold - 0.5) {
              icon = Icons.star_half_rounded;
            } else {
              icon = Icons.star_outline_rounded;
            }
            return Icon(icon, size: 7, color: color);
          }),
        ),
      ],
    );
  }
}

class _PropertyImage extends StatelessWidget {
  const _PropertyImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    if (url == null || url!.isEmpty) {
      return ColoredBox(
        color: b.searchFill,
        child: const Center(
          child: Icon(Icons.home_work_outlined, size: 28, color: RentalTheme.green),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: b.searchFill,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 24, color: RentalTheme.green),
        ),
      ),
    );
  }
}
