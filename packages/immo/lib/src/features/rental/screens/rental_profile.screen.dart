import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental_profile_role.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/screens/personal_information.screen.dart';

/// Profile tab — Billetterie-style layout; follows device light/dark.
class RentalProfileScreen extends StatelessWidget {
  const RentalProfileScreen({
    super.key,
    this.onNavigateToContracts,
    this.onCreateTenant,
    this.onCreateListing,
    this.onOpenFavorites,
    this.onOpenPayments,
  });

  final VoidCallback? onNavigateToContracts;
  final VoidCallback? onCreateTenant;
  final VoidCallback? onCreateListing;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenPayments;

  void _soon(BuildContext context, String label) {
    final b = ImmoBrand.rentalOf(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: b.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bientôt disponible',
          style: TextStyle(color: b.text, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '$label sera disponible prochainement.',
          style: TextStyle(color: b.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: b.primaryDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }


  Future<bool> _login(BuildContext context) async {
    final ok = await ImmoHostBridge.ensureLoggedIn(context);
    if (!context.mounted || !ok) return false;
    await RentalSessionScope.of(context).bootstrap();
    return RentalSessionScope.of(context).monPeyaUnlocked;
  }

  Future<void> _openPersonalInfo(BuildContext context) async {
    var session = RentalSessionScope.of(context);
    if (!session.monPeyaUnlocked) {
      final ok = await _login(context);
      if (!context.mounted || !ok) return;
      session = RentalSessionScope.of(context);
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PersonalInformationScreen(
          displayName: session.displayName,
          phone: session.phone,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return 'M';
    final list = parts.toList();
    if (list.length == 1) {
      final s = list.first;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s[0].toUpperCase();
    }
    return ('${list.first[0]}${list.last[0]}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final session = RentalSessionScope.of(context);
    final b = ImmoBrand.rentalOf(context);
    final textTheme = Theme.of(context).textTheme;
    final role = session.profileRole;
    final monPeyaUnlocked = session.monPeyaUnlocked;
    final immoReady = session.authenticated;
    final isGuest = !monPeyaUnlocked;
    final isClient = role.isClient;
    final name = session.displayName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: b.bg,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 8,
            20,
            RentalBottomNavigation.contentBottomPadding(context) + 24,
          ),
          children: [
            Text(
              'Profil',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: b.text,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: b.primaryDark.withValues(alpha: 0.12),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: b.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: b.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isGuest
                  ? 'Mode invité — parcourez les biens librement'
                  : 'Compte connecté',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: b.muted),
            ),
            if (isGuest) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _login(context),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Connexion'),
                style: FilledButton.styleFrom(
                  backgroundColor: b.primaryDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Client / Business switch only after Immo is linked; guests browse as clients.
            if (immoReady) ...[
              if (session.businessOnlyAccount)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: b.searchFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: b.border),
                  ),
                  child: Text(
                    'Compte fournisseur PeyaPay — espace propriétaire uniquement. '
                    'L’abonnement et les services s’effectuent côté professionnel.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: b.text,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                )
              else
                _ModeCard(
                  role: role,
                  onSwitchClient: () =>
                      session.setProfileRole(RentalProfileRole.seeker),
                  onSwitchBusiness: () =>
                      session.setProfileRole(RentalProfileRole.landlord),
                ),
              const SizedBox(height: 16),
            ],
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: Icons.badge_outlined,
                  label: 'Informations personnelles',
                  onTap: () => _openPersonalInfo(context),
                ),
                if (immoReady && isClient)
                  _SettingsItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Biens favoris',
                    onTap: onOpenFavorites ?? () {},
                  ),
                if (immoReady && !isClient)
                  _SettingsItem(
                    icon: Icons.storefront_outlined,
                    label: 'Espace propriétaire',
                    onTap: () =>
                        session.setProfileRole(RentalProfileRole.landlord),
                  ),
              ],
            ),
            if (immoReady) ...[
              const SizedBox(height: 14),
              _SettingsGroup(
                items: isClient
                    ? [
                        _SettingsItem(
                          icon: Icons.description_outlined,
                          label: 'Mes documents',
                          onTap: onNavigateToContracts ??
                              () => _soon(context, 'Mes documents'),
                        ),
                        _SettingsItem(
                          icon: Icons.payments_outlined,
                          label: 'Paiements',
                          onTap: onOpenPayments ??
                              () => _soon(context, 'Paiements'),
                        ),
                      ]
                    : [
                        _SettingsItem(
                          icon: Icons.home_work_outlined,
                          label: 'Publier un bien',
                          onTap: onCreateListing ??
                              () => _soon(context, 'Publier un bien'),
                        ),
                        _SettingsItem(
                          icon: Icons.person_add_outlined,
                          label: 'Nouveau locataire',
                          onTap: onCreateTenant ??
                              () => _soon(context, 'Nouveau locataire'),
                        ),
                        _SettingsItem(
                          icon: Icons.description_outlined,
                          label: 'Contrats',
                          onTap: onNavigateToContracts ??
                              () => _soon(context, 'Contrats'),
                        ),
                        _SettingsItem(
                          icon: Icons.insights_outlined,
                          label: 'Statistiques',
                          onTap: () => _soon(context, 'Statistiques'),
                        ),
                      ],
              ),
            ],
            const SizedBox(height: 14),
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: Icons.lock_outline_rounded,
                  label: isGuest ? 'Connexion' : 'Connexion & sécurité',
                  onTap: isGuest
                      ? () => _login(context)
                      : () => _soon(context, 'Connexion & sécurité'),
                ),
                _SettingsItem(
                  icon: Icons.headset_mic_outlined,
                  label: 'Support client',
                  onTap: () => _soon(context, 'Support client'),
                ),
                _SettingsItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Informations légales',
                  onTap: () => _soon(context, 'Informations légales'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.role,
    required this.onSwitchClient,
    required this.onSwitchBusiness,
  });

  final RentalProfileRole role;
  final VoidCallback onSwitchClient;
  final VoidCallback onSwitchBusiness;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: b.searchFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              selected: role.isClient,
              label: 'Client',
              onTap: onSwitchClient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeChip(
              selected: role.isBusiness,
              label: 'Business',
              onTap: onSwitchBusiness,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Material(
      color: selected ? b.primaryDark : b.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? b.primaryDark : b.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : b.text,
                ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: b.border),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: b.primaryDark),
      title: Text(
        label,
        style: TextStyle(
          color: b.text,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: b.muted),
    );
  }
}
