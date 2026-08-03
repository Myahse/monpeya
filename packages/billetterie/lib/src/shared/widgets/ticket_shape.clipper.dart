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

  /// Same geometry as [getClip] — used for clip + thin outline stroke.
  static Path buildPath({
    required Size size,
    required double cornerRadius,
    required double notchRadius,
    required double dividerFraction,
  }) {
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
  Path getClip(Size size) {
    return buildPath(
      size: size,
      cornerRadius: cornerRadius,
      notchRadius: notchRadius,
      dividerFraction: dividerFraction,
    );
  }

  @override
  bool shouldReclip(covariant TicketShapeClipper oldClipper) {
    return oldClipper.cornerRadius != cornerRadius ||
        oldClipper.notchRadius != notchRadius ||
        oldClipper.dividerFraction != dividerFraction;
  }
}

/// Thin outline following [TicketShapeClipper] (light theme contrast).
class TicketShapeBorderPainter extends CustomPainter {
  const TicketShapeBorderPainter({
    required this.cornerRadius,
    required this.notchRadius,
    required this.dividerFraction,
    required this.color,
    this.strokeWidth = 1.0,
  });

  final double cornerRadius;
  final double notchRadius;
  final double dividerFraction;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = TicketShapeClipper.buildPath(
      size: size,
      cornerRadius: cornerRadius,
      notchRadius: notchRadius,
      dividerFraction: dividerFraction,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant TicketShapeBorderPainter oldDelegate) {
    return oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.dividerFraction != dividerFraction ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
