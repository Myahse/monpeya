import 'package:flutter/material.dart';

import 'package:peyapay/src/core/constants/peya_pay.assets.dart';

/// PeyaPay brand mark for the bottom navigation bar and balance card.
class PeyaPayNavBarIcon extends StatelessWidget {
  const PeyaPayNavBarIcon({
    super.key,
    this.size = 24,
    this.width,
  });

  final double size;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      PeyaPayAssets.bank(PeyaPayAssets.brandLogo),
      package: PeyaPayAssets.package,
      width: width ?? size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
