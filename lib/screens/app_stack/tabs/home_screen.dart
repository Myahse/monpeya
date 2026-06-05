import 'package:flutter/material.dart';

import '../../../app/assets/asset_paths.dart';
import '../../../app/routing/routes.dart';
import '../../../app/storage/auth_store.dart';
import '../app_stack_scope.dart';
import '../app_stack_types.dart';
import '../mon_peya_my_services_screen.dart';
import '../widgets/module_scaffold.dart';
import '../widgets/nteri_news_carousel.dart';
import 'peyapay/screens/peyapay_add_money_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBalance = false;
  bool _immoFolderOpen = false;

  static const _fakeBalance = 5000.0;

  void _openService(String routeName, {required String moduleId}) {
    final appStack = AppStackScope.maybeOf(context);
    appStack?.openService(routeName, params: {'moduleId': moduleId});
  }

  void _openImmoFolder() => setState(() => _immoFolderOpen = true);
  void _closeImmoFolder() => setState(() => _immoFolderOpen = false);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final servicesCount = 1 /* folder */ + 1 /* billetterie */ + 1 /* placeholder */;

    return ModuleScaffold(
      title: 'HOME',
      showAppBar: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _HomeTopBar(
          title: 'Bienvenue,',
          onPressProfile: () => rootNavKey.currentState?.pushNamed(Routes.settings),
        ),
        const SizedBox(height: 12),
        _BalanceCard(
          showBalance: _showBalance,
          balance: _fakeBalance,
          onToggleShowBalance: () => setState(() => _showBalance = !_showBalance),
          onDeposit: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PeyapayAddMoneyScreen()),
            );
          },
        ),
        const SizedBox(height: 6),

        // Mon Peya (mini card under balance)
        _MonPeyaMiniCard(
          onTap: () async {
            final ok = await AuthStore.isRegistered();
            if (!context.mounted) return;

            if (!ok) {
              rootNavKey.currentState?.pushNamed(Routes.phoneInput);
              return;
            }

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MonPeyaMyServicesScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        // Actualités
        Text(
          'Actualités',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        const NteriNewsCarousel(height: 185,), // width: 350,

        const SizedBox(height: 18),

        // Mes services
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes services',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '3 services disponibles',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (servicesCount > 0)
              Text(
                '$servicesCount',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
          ],
        ),
        const SizedBox(height: 12),

        Stack(
          children: [
            _ServicesGrid(
              onOpenImmoFolder: _openImmoFolder,
              onOpenBilletterie: () => _openService(
                AppStackRoute.billetterie,
                moduleId: 'billetterie-electronique',
              ),
              onOpenPlaceholder: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service: à brancher.')),
                );
              },
            ),
            if (_immoFolderOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeImmoFolder,
                  child: Container(color: Colors.black.withValues(alpha: 0.25)),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: _ImmoFolderCard(
                  onClose: _closeImmoFolder,
                  onOpenRental: () => _openService(
                    AppStackRoute.mrImmoRental,
                    moduleId: 'mr-immo-rental',
                  ),
                  onOpenConstruction: () => _openService(
                    AppStackRoute.mrImmoConstruction,
                    moduleId: 'mr-immo-construction',
                  ),
                  onOpenCollection: () => _openService(
                    AppStackRoute.mrImmoCollection,
                    moduleId: 'mr-immo-collection',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.title,
    required this.onPressProfile,
  });

  final String title;
  final VoidCallback onPressProfile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: 40,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: 0,
        maxWidth: screenW,
        child: SizedBox(
          width: screenW,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: isDark ? Border(bottom: BorderSide(color: cs.outlineVariant)) : null,
            ),
            child: Padding(
              // Keep content aligned with page padding while border goes edge-to-edge.
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left "avatar dot" placeholder (like NTERI home header)
                  InkWell(
                    onTap: onPressProfile,
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: cs.onSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center title
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                  // Right side left empty on Home (matches NTERI)
                  const SizedBox(width: 36, height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonPeyaMiniCard extends StatelessWidget {
  const _MonPeyaMiniCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? AssetPaths.logoDark
                  : AssetPaths.logo,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mon espace personnel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.showBalance,
    required this.balance,
    required this.onToggleShowBalance,
    required this.onDeposit,
  });

  final bool showBalance;
  final double balance;
  final VoidCallback onToggleShowBalance;
  final VoidCallback onDeposit;

  String _formatFcfa(double v) {
    final whole = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final idxFromEnd = whole.length - i;
      buf.write(whole[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF006D56);
    const cardRadius = 30.0;

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background card image clipped to rounded corners
            Image.asset('assets/images/card_bg.png', fit: BoxFit.cover),

            // Green overlay so it matches the original super-app tint
            Container(color: green.withValues(alpha: 0.80)),

            // Foreground content with exact padding inside the clipped card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // QR box (image inside, clipped)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 96,
                      height: 96,
                      color: Colors.white,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/Code QR personnalisé.jpg',
                            fit: BoxFit.cover,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              color: Colors.white.withValues(alpha: 0.82),
                              child: const Text(
                                'scan here',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Balance side
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // On some devices (font scaling / small widths), this side can overflow by a few px.
                        // Switch to a compact layout when vertical space is tight.
                        final compact = constraints.maxHeight < 125;

                        final titleStyle = TextStyle(
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        );

                        final balanceStyle = TextStyle(
                          fontSize: compact ? 26 : 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        );

                        final depositHeight = compact ? 30.0 : 34.0;
                        final vGap1 = compact ? 4.0 : 6.0;
                        final vGap2 = compact ? 6.0 : 10.0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Total balance', style: titleStyle),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: onToggleShowBalance,
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: compact ? 26 : 28,
                                    height: compact ? 26 : 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Icon(
                                      showBalance
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: compact ? 16 : 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text('Fcfa', style: titleStyle),
                              ],
                            ),
                            SizedBox(height: vGap1),
                            Text(
                              showBalance ? _formatFcfa(balance) : '*****',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: balanceStyle,
                            ),
                            SizedBox(height: vGap2),
                            InkWell(
                              onTap: onDeposit,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                height: depositHeight,
                                padding: EdgeInsets.only(
                                  left: compact ? 12 : 14,
                                  right: compact ? 6 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Make a deposit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: compact ? 11 : 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: compact ? 8 : 10),
                                    Container(
                                      width: compact ? 24 : 26,
                                      height: compact ? 24 : 26,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: compact ? 16 : 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.onOpenImmoFolder,
    required this.onOpenBilletterie,
    required this.onOpenPlaceholder,
  });

  final VoidCallback onOpenImmoFolder;
  final VoidCallback onOpenBilletterie;
  final VoidCallback onOpenPlaceholder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const gap = 12.0;
        final tileW = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final iconSize = tileW < 80 ? 44.0 : 52.0;

        Widget tile({
          required Widget icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return SizedBox(
            width: tileW,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  children: [
                    Container(
                      width: iconSize + 15,
                      height: iconSize + 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: icon),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: [
            tile(
              icon: const Text('🏠', style: TextStyle(fontSize: 26)),
              label: 'Mr Immo',
              onTap: onOpenImmoFolder,
            ),
            tile(
              icon: const Icon(Icons.confirmation_number_outlined, size: 28, color: Colors.black87),
              label: 'Billetterie',
              onTap: onOpenBilletterie,
            ),
            tile(
              icon: const Text('🛒', style: TextStyle(fontSize: 26)),
              label: 'Mon Marché',
              onTap: onOpenPlaceholder,
            ),
          ],
        );
      },
    );
  }
}

class _ImmoFolderCard extends StatelessWidget {
  const _ImmoFolderCard({
    required this.onClose,
    required this.onOpenRental,
    required this.onOpenConstruction,
    required this.onOpenCollection,
  });

  final VoidCallback onClose;
  final VoidCallback onOpenRental;
  final VoidCallback onOpenConstruction;
  final VoidCallback onOpenCollection;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mr Immo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: [
                _FolderItem(icon: Icons.home_work_outlined, label: 'Rental', onTap: onOpenRental),
                _FolderItem(icon: Icons.construction_outlined, label: 'Construction', onTap: onOpenConstruction),
                _FolderItem(icon: Icons.collections_bookmark_outlined, label: 'Collection', onTap: onOpenCollection),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderItem extends StatelessWidget {
  const _FolderItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

