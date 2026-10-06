import 'package:flutter/material.dart';

import 'package:immo/src/features/construction/widgets/construction_payments.view.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConstructionPaymentsView(incoming: false);
  }
}
