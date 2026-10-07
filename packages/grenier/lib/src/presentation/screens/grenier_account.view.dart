import 'package:flutter/material.dart';

import 'package:grenier/src/core/host/grenier_host.bridge.dart';
import 'package:grenier/src/presentation/widgets/grenier_ui.dart';

/// "Mon compte": the Mon Peya identity used by Mon Grenier.
class GrenierAccountView extends StatelessWidget {
  const GrenierAccountView({
    super.key,
    required this.profile,
    required this.onExit,
  });

  final GrenierHostProfile? profile;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return GrenierHeaderPage(
      header: const GrenierHeaderTitle(eyebrow: 'Mon Grenier', title: 'Mon compte'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 22, 20, GrenierPillNav.clearance(context)),
        children: [
          GrenierRise(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: grenierCard(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: GrenierColors.primary,
                    child: p == null || p.initials.isEmpty
                        ? const Icon(Icons.person_outline_rounded, color: Colors.white)
                        : Text(
                            p.initials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p?.fullName ?? 'Invité',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        if (p?.phone != null)
                          Text(p!.phone!, style: const TextStyle(fontSize: 13.5, color: GrenierColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GrenierRise(
            delay: const Duration(milliseconds: 70),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: grenierCard(),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: GrenierColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Accès inclus dans votre abonnement Mon Peya. Mon Grenier affiche les prix et le détail des produits.',
                      style: TextStyle(fontSize: 13, color: GrenierColors.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GrenierRise(
            delay: const Duration(milliseconds: 140),
            child: GrenierPressable(
              onTap: onExit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: grenierCard(radius: 16),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: GrenierColors.soft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded, color: GrenierColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Retour à Mon Peya', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
