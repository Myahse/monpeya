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
    this.showPartnerDot = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final double width;
  final double? height;
  final bool selected;
  final bool showPartnerDot;

  static const tileAspectRatio = 1.22;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileH = height ?? width * tileAspectRatio;
    final bgColor = cs.brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : const Color(0xFFF5F5F5);
    final borderColor = selected ? cs.primary : cs.outlineVariant;

    return SizedBox(
      width: width,
      height: tileH,
      child: Material(
        color: selected ? cs.primaryContainer : bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                child: Column(
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
                ),
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
      ),
    );
  }
}
