import 'package:flutter/material.dart';

import '../billetterie_brand.dart';

class ServiceHomeScreen extends StatelessWidget {
  const ServiceHomeScreen({
    super.key,
    required this.onOpenEvents,
    required this.onOpenTickets,
    this.onOpenMonPeya,
  });

  final VoidCallback onOpenEvents;
  final VoidCallback onOpenTickets;
  final VoidCallback? onOpenMonPeya;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: BilletterieBrand.bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, top + 10, 16, 28),
        children: [
          const Text(
            'Billetterie',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BilletterieBrand.text),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, height: 20 / 14, color: BilletterieBrand.muted),
              children: const [
                TextSpan(text: 'Choisissez le service. Pour l\u2019instant, on a seulement '),
                TextSpan(text: 'Évènements', style: TextStyle(fontWeight: FontWeight.w900, color: BilletterieBrand.text)),
                TextSpan(text: ' et '),
                TextSpan(text: 'Cars', style: TextStyle(fontWeight: FontWeight.w900, color: BilletterieBrand.text)),
                TextSpan(text: '.'),
              ],
            ),
          ),
          if (onOpenMonPeya != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpenMonPeya,
                style: FilledButton.styleFrom(
                  backgroundColor: BilletterieBrand.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Mon Peya',
                  style: TextStyle(fontWeight: FontWeight.w900, color: BilletterieBrand.text),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _ServiceCard(
            title: 'Évènements',
            chip: 'Concert • Cinéma • Théâtre • …',
            description:
                'Parcourir ou créer des évènements. Les évènements créés apparaîtront ici, puis vous pouvez acheter des tickets.',
            onTap: onOpenEvents,
          ),
          const SizedBox(height: 12),
          _ServiceCard(
            title: 'Cars',
            chip: 'Hors évènement',
            description:
                'Créez des types de ticket “Cars”, définissez les infos, générez le QR code et gérez votre liste.',
            onTap: onOpenTickets,
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.chip,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String chip;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BilletterieBrand.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BilletterieBrand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: BilletterieBrand.text)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BilletterieBrand.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: BilletterieBrand.border),
                ),
                child: Text(chip, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: BilletterieBrand.primaryDark)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 13, height: 18 / 13, color: BilletterieBrand.muted)),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: BilletterieBrand.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Accéder',
                style: TextStyle(fontWeight: FontWeight.w900, color: BilletterieBrand.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
