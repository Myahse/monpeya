import 'package:flutter/material.dart';

class PeyapayQrScanOverlayPainter extends CustomPainter {
  PeyapayQrScanOverlayPainter({
    required this.scanAreaSize,
    required this.scanAreaTop,
  });

  final double scanAreaSize;
  final double scanAreaTop;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final holeRect = Rect.fromLTWH(
      (size.width - scanAreaSize) / 2,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(PeyapayQrScanOverlayPainter oldDelegate) {
    return oldDelegate.scanAreaSize != scanAreaSize || oldDelegate.scanAreaTop != scanAreaTop;
  }
}
