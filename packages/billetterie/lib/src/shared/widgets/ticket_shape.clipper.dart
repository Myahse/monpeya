import 'package:flutter/material.dart';

/// Shared perforated ticket silhouette (side notches + rounded corners).
class TicketShapeClipper extends CustomClipper<Path> {
  const TicketShapeClipper({
    required this.cornerRadius,
    required this.notchRadius,
    required this.dividerFraction,
  });

  final double cornerRadius;
  final double notchRadius;
  final double dividerFraction;

  @override
  Path getClip(Size size) {
    final dividerY = size.height * dividerFraction;
    final path = Path();
    final r = cornerRadius;
    final n = notchRadius;

    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, dividerY - n);
    path.arcToPoint(
      Offset(size.width, dividerY + n),
      radius: Radius.circular(n),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.lineTo(0, dividerY + n);
    path.arcToPoint(
      Offset(0, dividerY - n),
      radius: Radius.circular(n),
      clockwise: false,
    );
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant TicketShapeClipper oldClipper) {
    return oldClipper.cornerRadius != cornerRadius ||
        oldClipper.notchRadius != notchRadius ||
        oldClipper.dividerFraction != dividerFraction;
  }
}
