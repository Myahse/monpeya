import 'package:flutter/material.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/shell/screens/mon_peya_my_services.screen.dart';
import 'package:app/src/features/shell/widgets/dynamic_modules_grid.widget.dart';
import 'package:app/src/features/shell/widgets/module_scaffold.widget.dart';
import 'package:app/src/features/shell/widgets/nteri_news_carousel.widget.dart';
import 'package:app/src/features/shell/widgets/mon_peya_module_gate.widget.dart';
import 'package:peyapay/peyapay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBalance = false;
  final _moduleRepository = ModuleRepository();
  late Future<ModuleFetchResult> _modulesFuture;

  static const _fakeBalance = 5000.0;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _loadModules();
  }

  Future<ModuleFetchResult> _loadModules() => _moduleRepository.fetchModulesResult();

  void _refreshModules() {
    setState(() => _modulesFuture = _loadModules());
  }

  void _openModule(AppModule module) {
    openModuleIfRegistered(context, () {
      AppStackScope.maybeOf(context)?.openModule(module);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ModuleScaffold(
      title: 'HOME',
      showAppBar: false,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.viewPaddingOf(context).top + 16, 16, 24),
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

        // Mes services (dynamic — loaded from Spring Boot / mock)
        FutureBuilder<ModuleFetchResult>(
          future: _modulesFuture,
          builder: (context, snapshot) {
            final result = snapshot.data;
            final modules = result?.modules ?? const <AppModule>[];
            final loading = snapshot.connectionState != ConnectionState.done;
            final count = modules.length;
            final offline = result != null && result.usedBundledFallback;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mes services',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loading
                                ? 'Chargement...'
                                : '$count service${count == 1 ? '' : 's'} disponible${count == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    if (count > 0)
                      Text(
                        '$count',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
                if (result != null && (offline || result.stats.partnerCount > 0 || result.loadMode == ModuleLoadMode.bundledOnly)) ...[
                  const SizedBox(height: 8),
                  ModulesStatusBanner(result: result, onRetry: _refreshModules),
                ],
                const SizedBox(height: 12),
                if (loading)
                  const ModulesLoadingGrid()
                else
                  DynamicModulesGrid(
                    modules: modules,
                    onOpenModule: _openModule,
                  ),
              ],
            );
          },
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
                  // Left "avatar dot" placeholder 
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
