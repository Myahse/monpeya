import 'package:flutter/material.dart';

import 'package:peyapay/src/presentation/screens/peyapay_qr.screen.dart';

/// Opens the unified QR hub on the scanner tab.
class PeyapayQrScanScreen extends StatelessWidget {
  const PeyapayQrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PeyapayQrScreen(initialMode: PeyapayQrMode.scan);
  }
}
