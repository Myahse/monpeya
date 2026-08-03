import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';

/// Peya Pay brand mark for operator tiles in Leadway payment screens.
class LeadwayPeyapayLogo extends StatelessWidget {
  const LeadwayPeyapayLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: PeyaPayAssetImage(
        PeyaPayAssets.bank(PeyaPayAssets.brandLogo),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.account_balance_wallet_outlined,
          size: size * 0.85,
        ),
      ),
    );
  }
}
