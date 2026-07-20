import 'package:flutter/material.dart';

import 'package:peyapay/src/presentation/screens/peyapay_qr.screen.dart';

/// Opens the unified QR hub on the "Mon QR" tab.
class PeyapayQrCodeScreen extends StatelessWidget {
  const PeyapayQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PeyapayQrScreen(initialMode: PeyapayQrMode.myQr);
  }
}
