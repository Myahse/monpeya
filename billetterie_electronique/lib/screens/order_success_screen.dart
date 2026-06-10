import 'package:flutter/material.dart';

import '../billetterie_brand.dart';
import '../models/billetterie_event.dart';
import '../navigation/billetterie_main_navigation.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.args, required this.onDone});

  final OrderSuccessArgs args;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BilletterieBrand.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: BilletterieBrand.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: BilletterieBrand.primaryDark, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('Achat confirmé', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(args.eventName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('${args.ticketLabel} • ${formatBilletterieCurrency(args.total)}', style: const TextStyle(color: BilletterieBrand.muted)),
              const SizedBox(height: 8),
              const Text(
                'Votre billet est disponible dans Cars → Mes tickets.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BilletterieBrand.muted),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(backgroundColor: BilletterieBrand.primaryDark, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
