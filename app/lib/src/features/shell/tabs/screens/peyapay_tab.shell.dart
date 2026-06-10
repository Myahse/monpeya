import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';

/// PeyaPay tab — wallet UI is always reachable; transactions are gated separately.
class PeyapayTabShell extends StatelessWidget {
  const PeyapayTabShell({super.key});

  @override
  Widget build(BuildContext context) => const PeyapayScreen();
}
