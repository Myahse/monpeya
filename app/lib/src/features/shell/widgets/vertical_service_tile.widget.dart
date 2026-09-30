import 'package:flutter/material.dart';

/// Vertical rectangle tile: icon and label inside one container.
class VerticalServiceTile extends StatelessWidget {
  const VerticalServiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.width,
    this.height,
    this.selected = false,
    this.showLabel = true,
    this.showPartnerDot = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final double width;
  final double? height;
  final bool selected;
  final bool showLabel;
  final bool showPartnerDot;

  static const tileAspectRatio = 1.22;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileSide = showLabel ? (height ?? width * tileAspectRatio) : width;
    final bgColor = cs.brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : const Color(0xFFF5F5F5);
    final borderColor = selected ? cs.primary : cs.outlineVariant;
    final radius = showLabel ? 14.0 : 12.0;

    final tile = Material(
      color: selected ? cs.primaryContainer : bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(showLabel ? 6 : 4),
              child: showLabel
                  ? Column(
                      children: [
                        Expanded(child: Center(child: icon)),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: selected ? cs.onPrimaryContainer : cs.onSurface,
                          ),
                        ),
                      ],
                    )
                  : Center(child: icon),
            ),
            if (showPartnerDot)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? cs.primaryContainer : bgColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: width,
      height: showLabel ? tileSide : width,
      child: showLabel
          ? tile
          : Center(
              child: Tooltip(
                message: label,
                child: SizedBox(
                  width: width,
                  height: width,
                  child: tile,
                ),
              ),
            ),
    );
  }
}
