import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/models/rental_profile_role.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

class RentalProfilePicker extends StatelessWidget {
  const RentalProfilePicker({super.key, required this.onSelect});

  final ValueChanged<RentalProfileRole> onSelect;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(RentalTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comment utilisez-vous Mr Immo ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: b.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous pourrez changer ce choix plus tard dans Compte.',
            style: TextStyle(fontSize: 14, color: b.muted, height: 1.4),
          ),
          const SizedBox(height: RentalTheme.spacingLg),
          _RoleCard(
            icon: Icons.home_work_outlined,
            title: 'Je suis propriétaire',
            subtitle: 'Gérer mes biens, locataires et annonces',
            onTap: () => onSelect(RentalProfileRole.landlord),
          ),
          const SizedBox(height: RentalTheme.spacingMd),
          _RoleCard(
            icon: Icons.search,
            title: 'Je cherche à louer',
            subtitle: 'Parcourir les biens disponibles par ville',
            onTap: () => onSelect(RentalProfileRole.seeker),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
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
    final b = RentalTheme.of(context);
    return Material(
      color: b.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(RentalTheme.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: b.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: RentalTheme.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: RentalTheme.green),
              ),
              const SizedBox(width: RentalTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: b.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: b.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: b.muted),
            ],
          ),
        ),
      ),
    );
  }
}
