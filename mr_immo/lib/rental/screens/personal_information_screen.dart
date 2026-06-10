import 'package:flutter/material.dart';

import '../../immo_brand.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({
    super.key,
    this.phone,
    this.immoUserId,
  });

  final String? phone;
  final String? immoUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Informations personnelles'),
        backgroundColor: ImmoBrand.rentalPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Profil Mon Peya / Mr Immo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'authentification Mr Immo est liée à votre compte Mon Peya (téléphone + PIN).',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          _infoCard(Icons.phone_android, 'Téléphone Mon Peya', phone ?? '—'),
          _infoCard(Icons.badge_outlined, 'Identifiant Mr Immo', immoUserId ?? '—'),
          _infoCard(Icons.lock_outline, 'Connexion', 'Code PIN Mon Peya Pay'),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: ImmoBrand.rentalPrimary),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}
