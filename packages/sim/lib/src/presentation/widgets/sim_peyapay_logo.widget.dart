import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';

/// Logo Peya Pay pour l’étape moyen de paiement SIM.
class SimPeyapayLogo extends StatelessWidget {
  const SimPeyapayLogo({super.key, this.size = 44, this.padding = 6});

  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: PeyaPayAssetImage(
          PeyaPayAssets.bank(PeyaPayAssets.brandLogo),
          width: size - padding * 2,
          height: size - padding * 2,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.account_balance_wallet_outlined,
            size: size * 0.55,
            color: SimBrand.primary,
          ),
        ),
      ),
    );
  }
}
