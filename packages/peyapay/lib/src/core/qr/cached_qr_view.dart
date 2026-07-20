import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CachedQRView extends StatelessWidget {
  const CachedQRView({
    super.key,
    required this.qrContent,
    this.size = 200,
    this.padding = const EdgeInsets.all(10),
    this.gapless = false,
    this.backgroundColor = Colors.white,
    this.eyeStyle,
    this.dataModuleStyle,
    this.embeddedImage,
    this.embeddedImageStyle,
  });

  final String qrContent;
  final double size;
  final EdgeInsets padding;
  final bool gapless;
  final Color backgroundColor;
  final QrEyeStyle? eyeStyle;
  final QrDataModuleStyle? dataModuleStyle;
  final ImageProvider? embeddedImage;
  final QrEmbeddedImageStyle? embeddedImageStyle;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: qrContent,
      size: size,
      padding: padding,
      gapless: gapless,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      eyeStyle: eyeStyle ??
          const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
      dataModuleStyle: dataModuleStyle ??
          const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
      embeddedImage: embeddedImage,
      embeddedImageStyle: embeddedImageStyle,
    );
  }
}


const double peyapayQrFillFactor = 0.9;

/// Module ink: white on dark surfaces, black on light (theme-aware by default).
Color peyapayQrModuleColor(BuildContext context, {bool? lightOnDark}) {
  if (lightOnDark != null) {
    return lightOnDark ? Colors.white : Colors.black;
  }
  return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
}

QrEyeStyle peyapayQrEyeStyle(Color moduleColor) => QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: moduleColor,
    );

QrDataModuleStyle peyapayQrDataStyle(Color moduleColor) => QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: moduleColor,
    );

/// QR that expands to fill its parent (zero quiet zone, gapless modules).
class CachedQRFill extends StatelessWidget {
  const CachedQRFill({
    super.key,
    required this.qrContent,
    this.fillFactor = peyapayQrFillFactor,
    this.moduleColor,
    this.lightOnDark,
    this.backgroundColor = Colors.transparent,
  });

  final String qrContent;
  final double fillFactor;
  final Color? moduleColor;
  final bool? lightOnDark;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ink = moduleColor ?? peyapayQrModuleColor(context, lightOnDark: lightOnDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final edge = _shortestEdge(w, h) * fillFactor;
        if (edge <= 0) return const SizedBox.shrink();

        return Center(
          child: CachedQRView(
            qrContent: qrContent,
            size: edge,
            padding: EdgeInsets.zero,
            gapless: true,
            backgroundColor: backgroundColor,
            eyeStyle: peyapayQrEyeStyle(ink),
            dataModuleStyle: peyapayQrDataStyle(ink),
          ),
        );
      },
    );
  }

  static double _shortestEdge(double width, double height) {
    if (width.isFinite && height.isFinite) {
      return width < height ? width : height;
    }
    if (width.isFinite) return width;
    if (height.isFinite) return height;
    return 0;
  }
}
