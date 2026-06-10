import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../host/immo_host_bridge.dart';
import '../auth/rental_session_scope.dart';
import '../theme/rental_theme.dart';
import 'personal_information_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onNavigateToContracts,
    this.onCreateTenant,
    this.onExitModule,
  });

  final VoidCallback? onNavigateToContracts;
  final VoidCallback? onCreateTenant;
  final VoidCallback? onExitModule;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final session = RentalSessionScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            RentalTheme.spacingLg,
            MediaQuery.paddingOf(context).top + RentalTheme.spacingXxl,
            RentalTheme.spacingLg,
            RentalTheme.scrollBottomPad,
          ),
          children: [
            const Text(
              'Compte',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: RentalTheme.textPrimary,
              ),
            ),
            const SizedBox(height: RentalTheme.spacingLg),
            _section([
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Informations personnelles',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PersonalInformationScreen(
                        phone: null,
                        immoUserId: session.userId,
                      ),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.person_add_outlined,
                title: 'Nouveau locataire',
                onTap: widget.onCreateTenant,
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Documents',
                onTap: widget.onNavigateToContracts,
              ),
            ]),
            _section([
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Connexion & sécurité',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.language,
                title: 'Langue',
                onTap: () {},
              ),
            ]),
            _section([
              _SettingsTile(
                icon: Icons.support_agent_outlined,
                title: 'Assistance client',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.balance_outlined,
                title: 'Informations légales',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: RentalTheme.spacingLg),
            Center(
              child: TextButton(
                onPressed: _showLogoutDialog,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: RentalTheme.spacingSm),
            Center(
              child: Column(
                children: [
                  Text(
                    'Mr Immo',
                    style: TextStyle(
                      color: RentalTheme.greenMid,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Location',
                    style: TextStyle(
                      color: RentalTheme.greenMid.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: RentalTheme.spacingLg),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Colors.black, indent: RentalTheme.spacingLg),
            children[i],
          ],
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(RentalTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Déconnexion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: RentalTheme.spacingSm),
              const Text(
                'Voulez-vous quitter Mr Immo Location ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: RentalTheme.spacingXl),
              SizedBox(
                width: MediaQuery.sizeOf(ctx).width * 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: RentalTheme.modalCancelGradient,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, false),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Annuler',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Quitter',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      (widget.onExitModule ?? () => ImmoHostBridge.exitModule(context))();
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RentalTheme.spacingLg,
            vertical: RentalTheme.spacingLg,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: RentalTheme.textPrimary),
              const SizedBox(width: RentalTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: RentalTheme.textPrimary,
                  ),
                ),
              ),
              if (onTap != null)
                const Text(
                  '›',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
