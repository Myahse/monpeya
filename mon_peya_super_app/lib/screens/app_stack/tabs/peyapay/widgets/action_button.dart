import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.width,
    required this.bg,
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final double width;
  final Color bg;
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
              alignment: Alignment.center,
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 14 / 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

