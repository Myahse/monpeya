import 'package:flutter/material.dart';

import 'package:billetterie/src/presentation/constants/billetterie.brand.dart';

class BilletterieSettingsScreen extends StatelessWidget {
  const BilletterieSettingsScreen({
    super.key,
    required this.onResetPurpose,
    required this.onExit,
  });

  final VoidCallback onResetPurpose;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 24),
      children: [
        const Text('Paramètres', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        _SettingsTile(
          icon: Icons.switch_account_outlined,
          title: 'Changer de profil',
          subtitle: 'Acheteur, organisateur ou scanner',
          onTap: onResetPurpose,
        ),
        _SettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Paiement Mon Peya',
          subtitle: 'Les achats passent par Peya Pay',
          onTap: () {},
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Quitter Billetterie'),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Billetterie électronique',
            style: TextStyle(color: BilletterieBrand.primaryDark, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: BilletterieBrand.primaryDark),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
