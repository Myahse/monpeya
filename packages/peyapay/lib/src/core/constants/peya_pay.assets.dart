import 'package:flutter/material.dart';

/// Asset paths bundled in the [peyapay] package.
class PeyaPayAssets {
  PeyaPayAssets._();

  static const package = 'peyapay';

  static String logo(String relativePath) => 'assets/logo/$relativePath';

  static String bank(String fileName) => 'assets/logo/banks/$fileName';

  static String card(String fileName) => 'assets/logo/cards/$fileName';

  /// Official PeyaPay prepaid card face art (PNG for fast load).
  static const prepaidCardRecto = 'recto-carte-peya-pay.png';

  /// Official PeyaPay prepaid card back art (PNG for fast load).
  static const prepaidCardVerso = 'verso.png';

  /// Full-color PeyaPay brand mark (`assets/logo/banks/logo peya.png`).
  static const brandLogo = 'logo peya.png';
}

/// Loads an asset from the [peyapay] package bundle.
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
