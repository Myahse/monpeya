import 'package:flutter/material.dart';

import 'package:billetterie/src/presentation/constants/billetterie.brand.dart';
import 'package:billetterie/src/data/datasources/mock.events.dart';

class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key, required this.onResetPurpose});

  final VoidCallback onResetPurpose;

  @override
  Widget build(BuildContext context) {
    final events = mockBilletterieEvents;
    final totalSold = events.fold<int>(0, (sum, e) => sum + (e.ticketsSold ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text('Tableau de bord organisateur'),
        backgroundColor: const Color(0xFFF0F9FF),
        foregroundColor: const Color(0xFF0C4A6E),
        elevation: 0,
        actions: [
          TextButton(onPressed: onResetPurpose, child: const Text('Profil')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Tableau de bord organisateur',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0C4A6E)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(value: '${events.length}', label: 'Évènements'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(value: '$totalSold', label: 'Billets vendus'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Mes évènements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E)),
          ),
          const SizedBox(height: 12),
          for (final e in events) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E))),
                  const SizedBox(height: 4),
                  Text(
                    '${e.ticketsSold ?? 0} / ${e.expectedAttendees ?? 0} places · ${e.conversionRate ?? 0}% conversion',
                    style: const TextStyle(fontSize: 12, color: BilletterieBrand.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0EA5E9))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: BilletterieBrand.muted)),
        ],
      ),
    );
  }
}
