import 'package:flutter/material.dart';

import '../billetterie_brand.dart';
import '../constants/billetterie_prefs.dart';

class BilletterieTicketPurposeScreen extends StatelessWidget {
  const BilletterieTicketPurposeScreen({super.key, required this.onSelect});

  final ValueChanged<TicketPurpose> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BilletterieBrand.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Text(
              'Comment utilisez-vous la billetterie ?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: BilletterieBrand.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre compte Mon Peya est déjà connecté. Choisissez votre rôle — modifiable dans les paramètres.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 24),
            _PurposeCard(
              icon: Icons.confirmation_number_outlined,
              title: 'Acheter ou consulter mes billets',
              description: 'Parcourir les événements, réserver et voir mes achats.',
              onTap: () => onSelect(TicketPurpose.buyer),
            ),
            _PurposeCard(
              icon: Icons.event_outlined,
              title: 'Gérer mes événements',
              description: 'Ventes, billetterie et suivi pour vos événements.',
              onTap: () => onSelect(TicketPurpose.organizer),
            ),
            _PurposeCard(
              icon: Icons.qr_code_scanner,
              title: 'Contrôle d\'accès',
              description: 'Scanner les QR codes à l\'entrée (équipe sur site).',
              onTap: () => onSelect(TicketPurpose.scanner),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: BilletterieBrand.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: BilletterieBrand.primarySoft,
          child: Icon(icon, color: BilletterieBrand.primaryDark),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
