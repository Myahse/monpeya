import 'package:flutter/material.dart';

/// Asset paths bundled in the [peya_pay] package.
class PeyaPayAssets {
  PeyaPayAssets._();

  static const package = 'peya_pay';

  static String logo(String relativePath) => 'assets/logo/$relativePath';

  static String bank(String fileName) => 'assets/logo/banks/$fileName';

  static String card(String fileName) => 'assets/logo/cards/$fileName';
}

/// Loads an asset from the [peya_pay] package bundle.
class PeyaPayAssetImage extends StatelessWidget {
  const PeyaPayAssetImage(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      package: PeyaPayAssets.package,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
