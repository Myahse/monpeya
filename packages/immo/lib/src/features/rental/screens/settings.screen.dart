import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/screens/personal_information.screen.dart';

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
    final b = RentalTheme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: b.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: b.bg,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            RentalTheme.spacingLg,
            MediaQuery.paddingOf(context).top + RentalTheme.spacingXxl,
            RentalTheme.spacingLg,
            RentalBottomNavigation.contentBottomPadding(context),
          ),
          children: [
            Text(
              'Compte',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: b.text,
              ),
            ),
            const SizedBox(height: RentalTheme.spacingLg),
            _section(b, [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Informations personnelles',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PersonalInformationScreen(
                        displayName: session.displayName,
                        phone: session.phone,
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
            _section(b, [
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
            _section(b, [
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 18, color: b.text),
                    const SizedBox(width: 8),
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: b.text,
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
                      color: RentalTheme.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Location',
                    style: TextStyle(
                      color: RentalTheme.green.withValues(alpha: 0.8),
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

  Widget _section(ImmoRentalPalette b, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: RentalTheme.spacingLg),
      decoration: BoxDecoration(
        color: b.card,
        border: Border.all(color: b.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: b.border, indent: RentalTheme.spacingLg),
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
      builder: (ctx) {
        final db = RentalTheme.of(ctx);
        return Dialog(
          backgroundColor: db.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(RentalTheme.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Déconnexion',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: db.text),
                ),
                const SizedBox(height: RentalTheme.spacingSm),
                Text(
                  'Voulez-vous quitter Mr Immo Location ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: db.muted, height: 1.4),
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
                  child: Text(
                    'Quitter',
                    style: TextStyle(color: db.text, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final b = RentalTheme.of(context);
    return Material(
      color: b.card,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RentalTheme.spacingLg,
            vertical: RentalTheme.spacingLg,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: b.text),
              const SizedBox(width: RentalTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: b.text,
                  ),
                ),
              ),
              if (onTap != null)
                Text(
                  '›',
                  style: TextStyle(fontSize: 18, color: b.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
