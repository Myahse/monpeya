import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';

/// Empty shell for **Billetterie Événements** — UI not started yet.
class BilletterieEventModuleScreen extends StatelessWidget {
  const BilletterieEventModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Scaffold(
      backgroundColor: brand.bg,
      body: const SizedBox.expand(),
    );
  }
}
