import 'package:flutter/material.dart';

import '../billetterie_brand.dart';

class TicketsHomeScreen extends StatelessWidget {
  const TicketsHomeScreen({
    super.key,
    required this.onBack,
    required this.onOpenTypes,
    required this.onCreateTicket,
    required this.onMyTickets,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenTypes;
  final VoidCallback onCreateTicket;
  final VoidCallback onMyTickets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: const Text('Cars — Tickets'),
        backgroundColor: Colors.white,
        foregroundColor: BilletterieBrand.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Tickets génériques', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Hors événement — créez, encodez en QR et gérez vos tickets.', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          _ActionTile(icon: Icons.category_outlined, title: 'Types de tickets', subtitle: 'Définir Standard, VIP, Pass…', onTap: onOpenTypes),
          _ActionTile(icon: Icons.add_circle_outline, title: 'Créer un ticket', subtitle: 'Générer un QR pour un porteur', onTap: onCreateTicket),
          _ActionTile(icon: Icons.list_alt, title: 'Mes tickets', subtitle: 'Consulter et recharger', onTap: onMyTickets),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: BilletterieBrand.primarySoft, child: Icon(icon, color: BilletterieBrand.primaryDark)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
