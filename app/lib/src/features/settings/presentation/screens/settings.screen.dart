import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/storage/constants/prefs.keys.dart';
import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _isRegistered = false;
  String _phone = '';
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // In dev mode we can force-guest globally via AuthStore.
      // Still keep reading other prefs (phone/biometrics) for UI.
      _phone = prefs.getString(PrefsKeys.phoneNumber) ?? '';
      _biometricsEnabled = prefs.getBool(PrefsKeys.biometricEnabled) ?? false;
      _loading = false;
    });
    final ok = await AuthStore.hasAccount();
    if (!mounted) return;
    setState(() => _isRegistered = ok);
  }

  bool get _isGuest => !_isRegistered;

  Future<void> _setBiometrics(bool enabled) async {
    if (_isGuest) {
      await _showAuthRequiredModal(
        title: 'Connexion requise',
        message: 'Pour activer la connexion biométrique, connectez-vous d’abord.',
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.biometricEnabled, enabled);
    setState(() => _biometricsEnabled = enabled);
    await _showInfoModal(
      title: enabled ? 'Biométrie activée' : 'Biométrie désactivée',
      message: enabled
          ? 'Vous pourrez maintenant vous connecter avec Face ID / empreinte.'
          : 'Vous avez désactivé la connexion biométrique pour ce compte.',
    );
  }

  Future<void> _logout() async {
    final ok = await _showConfirmModal(
      title: 'Déconnexion',
      message: 'Voulez-vous vous déconnecter ?',
      confirmText: 'Déconnexion',
      cancelText: 'Annuler',
      confirmColor: const Color(0xFF006D56),
    );
    if (!ok) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.biometricEnabled, false);
    await AuthStore.endSession();
    await AuthStore.setImmoUserId(null);
    endMonPeyaSession();
    notifyMonPeyaSessionChanged();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _guardedAction({
    String? title,
    String? message,
    required Future<void> Function() action,
  }) async {
    if (_isGuest) {
      await _showAuthRequiredModal(title: title, message: message);
      return;
    }
    await action();
  }

  Future<void> _openRegistration() async {
    if (!mounted) return;
    Navigator.of(context).pushNamed(Routes.phoneInput);
  }

  Future<void> _showSnack(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showInfoModal({required String title, required String message}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CenteredModal(
        title: title,
        message: message,
        primary: _ModalButton(label: 'OK', onTap: () => Navigator.of(context).pop()),
      ),
    );
  }

  Future<void> _showAuthRequiredModal({String? title, String? message}) async {
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CenteredModal(
        title: title ?? 'Connexion requise',
        message: message ??
            'Pour continuer, vous devez vous connecter ou créer un compte. Voulez-vous continuer ?',
        primary: _ModalButton(
          label: 'Oui',
          onTap: () => Navigator.of(context).pop(true),
        ),
        secondary: _ModalButton.secondary(
          label: 'Non',
          onTap: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    if (go == true) {
      await _openRegistration();
    }
  }

  Future<bool> _showConfirmModal({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required Color confirmColor,
  }) async {
    if (!mounted) return false;
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CenteredModal(
        title: title,
        message: message,
        primary: _ModalButton(
          label: confirmText,
          background: confirmColor,
          onTap: () => Navigator.of(context).pop(true),
        ),
        secondary: _ModalButton.secondary(
          label: cancelText,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _SettingsHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          const SizedBox(height: 12),
                          _ProfileCard(
                            isRegistered: _isRegistered,
                            phone: _phone,
                          ),
                          _Section(
                            title: 'Devenir partenaire',
                            rows: [
                              _SettingsRow(
                                icon: Icons.business_center_outlined,
                                label: 'Devenir point de vente, distributeur ou marchand',
                                trailingChevron: true,
                                onTap: () => _showSnack('L’intégration des partenaires arrive bientôt.'),
                              ),
                            ],
                          ),
                          _Section(
                            title: "Agents N’TERI",
                            rows: [
                              _SettingsRow(
                                icon: Icons.location_on_outlined,
                                label: 'Trouver les points de vente près de vous',
                                trailingChevron: true,
                                onTap: () => _showSnack('La carte des points de vente arrive bientôt.'),
                              ),
                            ],
                          ),
                          _Section(
                            title: 'Détails du compte',
                            rows: [
                              _SettingsRow(
                                icon: Icons.person_outline,
                                label: 'Informations personnelles',
                                onTap: () => _guardedAction(
                                  action: () => _showSnack('Informations personnelles: bientôt.'),
                                ),
                              ),
                              _SettingsRow(
                                icon: Icons.credit_card_outlined,
                                label: 'Vérifier votre plafond',
                                onTap: () => _guardedAction(
                                  action: () => _showSnack('Plafond: bientôt.'),
                                ),
                              ),
                              _SettingsRow(
                                icon: Icons.share_outlined,
                                label: 'Inviter un ami à rejoindre N’TERI',
                                onTap: () => _showSnack('Invitation: bientôt.'),
                              ),
                            ],
                          ),
                          _Section(
                            title: 'Sécurité',
                            rows: [
                              _SettingsRow.toggle(
                                icon: Icons.fingerprint,
                                label: 'Connexion biométrique',
                                value: _biometricsEnabled,
                                onChanged: (v) => _setBiometrics(v),
                              ),
                              _SettingsRow(
                                icon: Icons.lock_outline,
                                label: 'Réinitialiser le code PIN',
                                trailingChevron: true,
                                onTap: () => _guardedAction(
                                  title: 'Connexion requise',
                                  message:
                                      'Pour réinitialiser votre code PIN, connectez-vous d’abord.',
                                  action: () async => Navigator.of(context).pushNamed(Routes.resetPin),
                                ),
                              ),
                            ],
                          ),
                          _Section(
                            title: 'Messages',
                            rows: [
                              _SettingsRow(
                                icon: Icons.chat_bubble_outline,
                                label: 'Voir tous les messages',
                                trailingChevron: true,
                                onTap: () => _showSnack('Messages: bientôt.'),
                              ),
                            ],
                          ),
                          _Section(
                            title: 'À propos',
                            rows: [
                              _SettingsRow(
                                icon: Icons.info_outline,
                                label: "À propos de Mon Peya",
                                trailingChevron: true,
                                onTap: () => _showSnack("À propos: bientôt."),
                              ),
                            ],
                          ),
                          _Section(
                            title: 'Aide et support',
                            rows: [
                              _SettingsRow(
                                icon: Icons.headset_mic_outlined,
                                label: 'Contacter le support',
                                onTap: () => _showSnack('Support: bientôt (WhatsApp / appel).'),
                              ),
                            ],
                          ),
                          _Section(
                            title: '',
                            rows: [
                              if (_isGuest)
                                _SettingsRow(
                                  icon: Icons.login,
                                  label: 'Se connecter',
                                  onTap: _openRegistration,
                                ),
                              if (!_isGuest)
                                _SettingsRow(
                                  icon: Icons.logout,
                                  label: 'Déconnexion',
                                  danger: true,
                                  onTap: _logout,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(999),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.chevron_left, size: 26),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Paramètres',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.isRegistered, required this.phone});
  final bool isRegistered;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nameLine = isRegistered ? (phone.isNotEmpty ? phone : '—') : 'Invité';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.onSurface,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameLine,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isRegistered && phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(phone, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ...rows.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailingChevron = false,
    this.danger = false,
    this.onTap,
  })  : value = null,
        onChanged = null;

  final IconData icon;
  final String label;
  final bool trailingChevron;
  final bool danger;
  final VoidCallback? onTap;

  const _SettingsRow.toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  })  : trailingChevron = false,
        danger = false,
        onTap = null;

  final bool? value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isToggle = value != null && onChanged != null;
    final labelColor = danger ? cs.error : cs.onSurface;
    final iconColor = danger ? cs.error : cs.onSurfaceVariant;

    return InkWell(
      onTap: isToggle ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor),
              ),
            ),
            if (isToggle)
              _SettingsToggle(value: value!, onChanged: onChanged!)
            else if (trailingChevron)
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF16A34A) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredModal extends StatelessWidget {
  const _CenteredModal({
    required this.title,
    required this.message,
    required this.primary,
    this.secondary,
  });

  final String title;
  final String message;
  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            primary,
            if (secondary != null) ...[
              const SizedBox(height: 10),
              secondary!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  const _ModalButton({
    required this.label,
    required this.onTap,
    this.background = const Color(0xFF006D56),
  }) : foreground = null;

  const _ModalButton.secondary({
    required this.label,
    required this.onTap,
  })  : background = const Color(0xFFE5E7EB),
        foreground = null;

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = foreground ?? cs.onPrimary;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}


