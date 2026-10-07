import 'package:flutter/material.dart';

import 'package:grenier/src/core/host/grenier_host.bridge.dart';
import 'package:grenier/src/presentation/widgets/grenier_ui.dart';
import 'package:grenier/src/shared/services/grenier_account.service.dart';

/// "Mon compte": Mon Peya identity and the Mon Grenier account link.
class GrenierAccountView extends StatelessWidget {
  const GrenierAccountView({
    super.key,
    required this.profile,
    required this.link,
    required this.onLink,
    required this.onUnlink,
    required this.onExit,
  });

  final GrenierHostProfile? profile;
  final GrenierAccountLink? link;
  final VoidCallback onLink;
  final VoidCallback onUnlink;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final l = link;
    String date(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
                        : Text(p.initials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p?.fullName ?? 'Invité', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Compte Mon Grenier', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      _StatusChip(linked: l != null),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (l != null) ...[
                    Row(
                      children: [
                        Expanded(child: _Info(label: 'Identifiant', value: l.accountId)),
                        Expanded(child: _Info(label: 'Relié depuis', value: date(l.linkedAt))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Votre nom et votre téléphone Mon Peya ont été transmis à Mon Grenier lors de la création du compte.',
                      style: TextStyle(fontSize: 12.5, color: GrenierColors.muted, height: 1.4),
                    ),
                  ] else ...[
                    const Text(
                      'Créez votre compte Mon Grenier en un geste, avec vos informations Mon Peya.',
                      style: TextStyle(fontSize: 13, color: GrenierColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onLink,
                      style: FilledButton.styleFrom(
                        backgroundColor: GrenierColors.primary,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Créer mon compte', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (l != null)
            GrenierRise(
              delay: const Duration(milliseconds: 140),
              child: _Row(
                icon: Icons.link_off_rounded,
                title: 'Délier mon compte',
                subtitle: 'Arrêter le partage avec Mon Grenier',
                danger: true,
                onTap: () => _confirmUnlink(context),
              ),
            ),
          GrenierRise(
            delay: const Duration(milliseconds: 180),
            child: _Row(
              icon: Icons.logout_rounded,
              title: 'Retour à Mon Peya',
              subtitle: 'Quitter Mon Grenier',
              onTap: onExit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlink(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Délier votre compte ?'),
        content: const Text(
          'Mon Peya ne partagera plus vos informations avec Mon Grenier sur cet appareil.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            child: const Text('Délier'),
          ),
        ],
      ),
    );
    if (ok == true) onUnlink();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.linked});

  final bool linked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: linked ? GrenierColors.soft : const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: linked ? GrenierColors.primary : GrenierColors.muted,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            linked ? 'Relié' : 'Non relié',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: linked ? GrenierColors.dark : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: GrenierColors.muted)),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFB91C1C) : GrenierColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GrenierPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: grenierCard(radius: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: danger ? const Color(0xFFFDECEC) : GrenierColors.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: danger ? fg : GrenierColors.text,
                        )),
                    Text(subtitle, style: const TextStyle(fontSize: 12.5, color: GrenierColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
