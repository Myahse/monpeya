import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/event/widgets/event_bottom_nav.widget.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

enum EventProfileRole { client, business }


class EventProfileScreen extends StatefulWidget {
  const EventProfileScreen({
    super.key,
    required this.role,
    required this.onRoleChanged,
    this.merchantOnly = false,
    this.onScanTickets,
  });

  final EventProfileRole role;
  final ValueChanged<EventProfileRole> onRoleChanged;
  final bool merchantOnly;
  final VoidCallback? onScanTickets;

  @override
  State<EventProfileScreen> createState() => _EventProfileScreenState();
}

class _EventProfileScreenState extends State<EventProfileScreen> {
  BilletterieClientIdentity? _identity;
  String _displayName = BilletterieHostBridge.guestDisplayName;
  bool _loading = true;

  bool get _isGuest => _identity == null;

  @override
  void initState() {
    super.initState();
    BilletterieHostBridge.sessionChanges?.addListener(_onHostSessionChanged);
    _reload();
  }

  @override
  void dispose() {
    BilletterieHostBridge.sessionChanges?.removeListener(_onHostSessionChanged);
    super.dispose();
  }

  void _onHostSessionChanged() => _reload();

  Future<void> _reload() async {
    final firstLoad = _loading;
    if (firstLoad) {
      setState(() => _loading = true);
    }
    final identity = await BilletterieHostBridge.resolveClientOrNull();
    if (!mounted) return;
    final guest = BilletterieHostBridge.guestDisplayName;
    setState(() {
      _identity = identity;
      _displayName = identity == null
          ? guest
          : (identity.resolvedDisplayName.trim().isEmpty
              ? guest
              : identity.resolvedDisplayName.trim());
      _loading = false;
    });
  }

  Future<void> _connect() async {
    final ok = await BilletterieHostBridge.promptLogin(context);
    if (!mounted) return;
    if (ok) await _reload();
  }

  void _soon(String label) {
    showBilletterieResultDialog(
      context,
      title: 'Bientôt disponible',
      message: '$label sera disponible prochainement.',
      kind: BilletterieResultKind.info,
      brand: BilletterieBrand.eventOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final textTheme = Theme.of(context).textTheme;
    final isClient = widget.role == EventProfileRole.client;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        BilletterieEventBottomNav.contentBottomPadding(context) + 24,
      ),
      children: [
        Text(
          'Profil',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: brand.text,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _displayName,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: brand.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isGuest
              ? 'Mode invité — découvrez les événements librement'
              : 'Compte connecté',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: brand.muted),
        ),
        if (_isGuest) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _connect,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Connexion'),
            style: FilledButton.styleFrom(
              backgroundColor: brand.primaryDark,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (!_isGuest) ...[
          if (widget.merchantOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: brand.primarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brand.border),
              ),
              child: Text(
                'Compte marchand PeyaPay — espace organisateur uniquement.',
                style: textTheme.bodyMedium?.copyWith(
                  color: brand.text,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            )
          else
            _ModeCard(
              brand: brand,
              role: widget.role,
              onSwitchClient: () =>
                  widget.onRoleChanged(EventProfileRole.client),
              onSwitchBusiness: () =>
                  widget.onRoleChanged(EventProfileRole.business),
            ),
          const SizedBox(height: 16),
        ],
        _SettingsGroup(
          brand: brand,
          items: [
            _SettingsItem(
              icon: Icons.badge_outlined,
              label: 'Informations personnelles',
              onTap: _isGuest
                  ? _connect
                  : () => _soon('Informations personnelles'),
            ),
            if (!_isGuest && isClient)
              _SettingsItem(
                icon: Icons.favorite_border_rounded,
                label: 'Événements favoris',
                onTap: () => _soon('Événements favoris'),
              ),
            if (!_isGuest && !isClient)
              _SettingsItem(
                icon: Icons.storefront_outlined,
                label: 'Espace organisateur',
                onTap: () =>
                    widget.onRoleChanged(EventProfileRole.business),
              ),
          ],
        ),
        if (!_isGuest) ...[
          const SizedBox(height: 14),
          _SettingsGroup(
            brand: brand,
            items: isClient
                ? [
                    _SettingsItem(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Mes billets',
                      onTap: () => _soon('Mes billets'),
                    ),
                    _SettingsItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Abonnement événements',
                      onTap: () => _soon('Abonnement événements'),
                    ),
                  ]
                : [
                    _SettingsItem(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scanner des billets',
                      onTap: widget.onScanTickets ??
                          () => _soon('Scanner des billets'),
                    ),
                    _SettingsItem(
                      icon: Icons.insights_outlined,
                      label: 'Statistiques',
                      onTap: () => _soon('Statistiques'),
                    ),
                  ],
          ),
        ],
        const SizedBox(height: 14),
        _SettingsGroup(
          brand: brand,
          items: [
            _SettingsItem(
              icon: Icons.lock_outline_rounded,
              label: _isGuest ? 'Connexion' : 'Connexion & sécurité',
              onTap: _isGuest
                  ? _connect
                  : () => _soon('Connexion & sécurité'),
            ),
            _SettingsItem(
              icon: Icons.headset_mic_outlined,
              label: 'Support client',
              onTap: () => _soon('Support client'),
            ),
            _SettingsItem(
              icon: Icons.verified_user_outlined,
              label: 'Informations légales',
              onTap: () => _soon('Informations légales'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.brand,
    required this.role,
    required this.onSwitchClient,
    required this.onSwitchBusiness,
  });

  final BilletterieBrand brand;
  final EventProfileRole role;
  final VoidCallback onSwitchClient;
  final VoidCallback onSwitchBusiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brand.searchFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              brand: brand,
              selected: role == EventProfileRole.client,
              label: 'Client',
              onTap: onSwitchClient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeChip(
              brand: brand,
              selected: role == EventProfileRole.business,
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
    required this.brand,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final BilletterieBrand brand;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? brand.primaryDark : brand.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? brand.primaryDark : brand.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : brand.text,
                ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.brand, required this.items});

  final BilletterieBrand brand;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: brand.border),
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
    final brand = BilletterieBrand.eventOf(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: brand.primaryDark),
      title: Text(
        label,
        style: TextStyle(
          color: brand.text,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: brand.muted),
    );
  }
}
