import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

/// Keys / access tab — contracts & digital access entry.
class KeysScreen extends StatelessWidget {
  const KeysScreen({
    super.key,
    this.onOpenContracts,
    this.onOpenPayments,
    this.onOpenMessages,
  });

  final VoidCallback? onOpenContracts;
  final VoidCallback? onOpenPayments;
  final VoidCallback? onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: b.bg,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              RentalBottomNavigation.contentBottomPadding(context),
            ),
            children: [
              Text(
                'Keys',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: b.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contrats, accès et paiements liés à vos biens.',
                style: TextStyle(color: b.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _KeysTile(
                icon: Icons.description_outlined,
                title: 'Contrats',
                subtitle: 'Voir vos documents de location',
                onTap: onOpenContracts,
              ),
              const SizedBox(height: 12),
              _KeysTile(
                icon: Icons.payments_outlined,
                title: 'Paiements',
                subtitle: 'Loyers et historique',
                onTap: onOpenPayments,
              ),
              const SizedBox(height: 12),
              _KeysTile(
                icon: Icons.chat_bubble_outline,
                title: 'Messages',
                subtitle: 'Conversations avec propriétaires / locataires',
                onTap: onOpenMessages,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeysTile extends StatelessWidget {
  const _KeysTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return Material(
      color: b.searchFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: RentalTheme.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: RentalTheme.green),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: b.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: b.muted,
                      ),
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
