import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/models/transport_profile.model.dart';
import 'package:billetterie/src/features/transport/screens/transport_conductor_upgrade.screen.dart';
import 'package:billetterie/src/features/transport/screens/transport_documents.screen.dart';
import 'package:billetterie/src/features/transport/screens/transport_notifications.screen.dart';
import 'package:billetterie/src/features/transport/screens/transport_personal_info.screen.dart';
import 'package:billetterie/src/features/transport/services/billetterie_notification.store.dart';
import 'package:billetterie/src/features/transport/services/transport_profile.store.dart';
import 'package:billetterie/src/shared/widgets/billetterie_bottom_nav.widget.dart';
import 'package:billetterie/src/shared/widgets/billetterie_skeleton.widget.dart';

/// Profile tab — user info + settings groups; subscribe / conductor only here.
class TransportProfileScreen extends StatefulWidget {
  const TransportProfileScreen({super.key});

  @override
  State<TransportProfileScreen> createState() => _TransportProfileScreenState();
}

class _TransportProfileScreenState extends State<TransportProfileScreen> {
  final _store = TransportProfileStore();
  final _notifications = BilletterieNotificationStore();

  TransportProfileState _state = const TransportProfileState();
  BilletterieClientIdentity? _identity;
  bool _loading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final state = await _store.load();
      final unread = await _notifications.unreadCount();
      BilletterieClientIdentity? identity;
      try {
        identity = await BilletterieHostBridge.requireClient();
      } catch (_) {
        identity = null;
      }
      if (!mounted) return;
      setState(() {
        _state = state;
        _identity = identity;
        _unreadNotifications = unread;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const TransportNotificationsScreen(),
      ),
    );
    if (!mounted) return;
    final unread = await _notifications.unreadCount();
    if (!mounted) return;
    setState(() => _unreadNotifications = unread);
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — bientôt disponible'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPersonalInfo() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TransportPersonalInfoScreen(
          identity: _identity,
          profile: _state,
        ),
      ),
    );
  }

  Future<void> _subscribeAsClient() async {
    if (_state.canUseAsClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abonnement client déjà actif'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final next = await _store.requestClientSubscribe();
    if (!mounted) return;
    setState(() => _state = next);
    final active = await _store.activateClient();
    if (!mounted) return;
    setState(() => _state = active);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abonnement client activé'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openDocuments() async {
    final updated = await Navigator.of(context).push<TransportProfileState>(
      MaterialPageRoute(
        builder: (_) => TransportDocumentsScreen(initial: _state),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _state = updated);
    } else {
      await _reload();
    }
  }

  Future<void> _openBecomeConductor() async {
    final updated = await Navigator.of(context).push<TransportProfileState>(
      MaterialPageRoute(
        builder: (_) => TransportConductorUpgradeScreen(initial: _state),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _state = updated);
    } else {
      await _reload();
    }
  }

  Future<void> _switchRole(TransportProfileRole role) async {
    final next = role == TransportProfileRole.conductor
        ? await _store.switchToConductorMode()
        : await _store.switchToClientMode();
    if (!mounted) return;
    setState(() => _state = next);
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const BilletterieProfileSkeleton();
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        BilletterieBottomNav.contentBottomPadding(context) + 24,
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
        const SizedBox(height: 20),
        _ModeCard(
          brand: brand,
          state: _state,
          onSwitchClient: () => _switchRole(TransportProfileRole.client),
          onSwitchConductor: _state.canUseAsConductor
              ? () => _switchRole(TransportProfileRole.conductor)
              : null,
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          brand: brand,
          items: [
            _SettingsItem(
              icon: Icons.badge_outlined,
              label: 'Informations personnelles',
              onTap: _openPersonalInfo,
            ),
            _SettingsItem(
              icon: Icons.folder_outlined,
              label: 'Documents',
              trailing: _state.hasAnyDocument ? 'OK' : null,
              onTap: _openDocuments,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsGroup(
          brand: brand,
          items: [
            _SettingsItem(
              icon: Icons.confirmation_number_outlined,
              label: 'Abonnement billets',
              trailing: _state.canUseAsClient ? 'Actif' : null,
              onTap: _subscribeAsClient,
            ),
            _SettingsItem(
              icon: Icons.directions_bus_outlined,
              label: 'Devenir conducteur',
              trailing: _state.canUseAsConductor
                  ? 'Actif'
                  : (_state.hasConductorRequestPending ||
                          _state.hasPartnerRequestPending
                      ? 'En cours'
                      : null),
              onTap: _openBecomeConductor,
            ),
            if (_state.peyapayMerchant)
              _SettingsItem(
                icon: Icons.storefront_outlined,
                label: 'Marchand PeyaPay',
                trailing: 'Détecté',
                onTap: () => _soon('Marchand PeyaPay'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsGroup(
          brand: brand,
          items: [
            _SettingsItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Messages',
              onTap: () => _soon('Messages'),
            ),
            _SettingsItem(
              icon: Icons.notifications_none_rounded,
              label: 'Alertes & notifications',
              badgeCount: _unreadNotifications,
              onTap: _openNotifications,
            ),
            _SettingsItem(
              icon: Icons.lock_outline_rounded,
              label: 'Connexion & sécurité',
              onTap: () => _soon('Connexion & sécurité'),
            ),
            _SettingsItem(
              icon: Icons.translate_rounded,
              label: 'Paramètres de langue',
              onTap: () => _soon('Paramètres de langue'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsGroup(
          brand: brand,
          items: [
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
        if (kDebugMode &&
            (_state.hasConductorRequestPending ||
                _state.hasPartnerRequestPending)) ...[
          const SizedBox(height: 12),
          if (_state.hasPartnerRequestPending)
            TextButton(
              onPressed: () async {
                final next = await _store.activatePartner();
                if (!mounted) return;
                setState(() => _state = next);
              },
              child: const Text('Debug : valider la demande partenaire'),
            ),
          if (_state.hasConductorRequestPending)
            TextButton(
              onPressed: () async {
                final next = await _store.activateConductor();
                if (!mounted) return;
                setState(() => _state = next);
              },
              child: const Text('Debug : valider la demande conducteur'),
            ),
        ],
      ],
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final int badgeCount;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.brand,
    required this.items,
  });

  final BilletterieBrand brand;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: brand.border, indent: 56),
            _SettingsTile(brand: brand, item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.brand, required this.item});

  final BilletterieBrand brand;
  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(item.icon, size: 22, color: brand.text),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: brand.text,
                      ),
                ),
              ),
              if (item.badgeCount > 0) ...[
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: brand.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ] else if (item.trailing != null) ...[
                Text(
                  item.trailing!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: brand.muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded, color: brand.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.brand,
    required this.state,
    required this.onSwitchClient,
    this.onSwitchConductor,
  });

  final BilletterieBrand brand;
  final TransportProfileState state;
  final VoidCallback onSwitchClient;
  final VoidCallback? onSwitchConductor;

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
              selected: state.isClientMode,
              label: 'Client',
              onTap: onSwitchClient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeChip(
              brand: brand,
              selected: state.isConductorMode,
              label: 'Conducteur',
              onTap: onSwitchConductor,
              enabled: onSwitchConductor != null,
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
    this.onTap,
    this.enabled = true,
  });

  final BilletterieBrand brand;
  final bool selected;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = selected && enabled;
    return Material(
      color: active ? brand.primary : brand.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? brand.primary : brand.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.white
                      : (enabled ? brand.text : brand.muted),
                ),
          ),
        ),
      ),
    );
  }
}
