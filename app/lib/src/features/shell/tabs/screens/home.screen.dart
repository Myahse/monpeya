import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/features/shell/screens/mon_peya_my_services.screen.dart';
import 'package:app/src/features/shell/services/module_launcher.service.dart';
import 'package:app/src/core/modules/widgets/module.icon.dart';
import 'package:peyapay/peyapay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBalance = false;
  static const _fakeBalance = 5000.0;

  void _openModule(AppModule module) {
    ModuleLauncher.open(context, module);
  }

  void _showHomeActionSnack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label : bientôt.')),
    );
  }

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
    final cs = Theme.of(context).colorScheme;
    // Horizontal/bottom shell padding only — top is handled by the gradient header.
    const hPad = 16.0;
    final botPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: cs.brightness == Brightness.dark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF4F6F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header gradient ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _GradientHeader(
              showBalance: _showBalance,
              balance: _fakeBalance,
              formatFcfa: _formatFcfa,
              onToggleBalance: () =>
                  setState(() => _showBalance = !_showBalance),
              onPressProfile: () =>
                  rootNavKey.currentState?.pushNamed(Routes.settings),
              onPressNotifications: () =>
                  _showHomeActionSnack(context, 'Notifications'),
              onDeposit: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PeyapayAddMoneyScreen(),
                ),
              ),
              onSend: () => _showHomeActionSnack(context, 'Envoyer'),
              onScan: () => _showHomeActionSnack(context, 'Scanner'),
            ),
          ),

          // ─── Content ──────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, botPad + 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Mon espace
                _MonPeyaMiniCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MonPeyaMyServicesScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Actualités
                _SectionHeader(
                  title: 'Actualités',
                  actionLabel: 'Voir tout',
                  onAction: () => _showHomeActionSnack(context, 'Actualités'),
                ),
                const SizedBox(height: 12),
                const _HorizontalNewsCarousel(height: 160),

                const SizedBox(height: 28),

                // Services
                Builder(builder: (context) {
                  final modules = ModuleRepository.modules;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Mes services',
                        actionLabel:
                            '${modules.length} disponible${modules.length > 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: 14),
                      _ServiceGrid(
                        modules: modules,
                        onOpen: _openModule,
                      ),
                    ],
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRADIENT HEADER  (top bar + balance card + quick actions)
// ═══════════════════════════════════════════════════════════════════════════

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.showBalance,
    required this.balance,
    required this.formatFcfa,
    required this.onToggleBalance,
    required this.onPressProfile,
    required this.onPressNotifications,
    required this.onDeposit,
    required this.onSend,
    required this.onScan,
  });

  final bool showBalance;
  final double balance;
  final String Function(double) formatFcfa;
  final VoidCallback onToggleBalance;
  final VoidCallback onPressProfile;
  final VoidCallback onPressNotifications;
  final VoidCallback onDeposit;
  final VoidCallback onSend;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006D56), Color(0xFF00453B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Subtle pattern circles
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 40, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: onPressProfile,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4), width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue 👋',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Mon Peya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    GestureDetector(
                      onTap: onPressNotifications,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5252),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Balance section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Solde disponible',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onToggleBalance,
                                child: Icon(
                                  showBalance
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white.withOpacity(0.75),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                showBalance ? formatFcfa(balance) : '• • • • •',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              if (showBalance) ...[
                                const SizedBox(width: 6),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'FCFA',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // QR Code
                    GestureDetector(
                      onTap: onScan,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/Code QR personnalisé.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.add_rounded,
                      label: 'Recharger',
                      onTap: onDeposit,
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.send_rounded,
                      label: 'Envoyer',
                      onTap: onSend,
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scanner',
                      onTap: onScan,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MON PEYA MINI CARD
// ═══════════════════════════════════════════════════════════════════════════

class _MonPeyaMiniCard extends StatelessWidget {
  const _MonPeyaMiniCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF006D56).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF006D56),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon espace personnel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Paramètres, profil & préférences',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF006D56).withOpacity(0.8),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HORIZONTAL NEWS CAROUSEL  (cards with peek effect)
// ═══════════════════════════════════════════════════════════════════════════

class _HorizontalNewsCarousel extends StatefulWidget {
  const _HorizontalNewsCarousel({this.height = 160});
  final double height;

  @override
  State<_HorizontalNewsCarousel> createState() =>
      _HorizontalNewsCarouselState();
}

class _HorizontalNewsCarouselState extends State<_HorizontalNewsCarousel> {
  final _controller = ScrollController();
  int _activeIndex = 0;

  static const _items = [
    (
      title: 'TukShopp Campus Connect',
      subtitle: 'Événement • Jeux • Cadeaux',
      imageAsset: 'assets/images/ad-1.jpg',
      badge: 'Événement',
      color: Color(0xFF1A237E),
    ),
    (
      title: 'Essence Academy',
      subtitle: 'Formations • Figma • Canva',
      imageAsset: 'assets/images/ad-2.jpg',
      badge: 'Formation',
      color: Color(0xFF1B5E20),
    ),
    (
      title: 'GEN Z FEST 2026',
      subtitle: 'Hangout • Music • Games',
      imageAsset: 'assets/images/ad-1.jpg',
      badge: 'Festival',
      color: Color(0xFF4A148C),
    ),
    (
      title: 'Exploration 2026',
      subtitle: 'Conférence • Youth Festival',
      imageAsset: 'assets/images/ad-2.jpg',
      badge: 'Conférence',
      color: Color(0xFF004D40),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 240.0;
    const cardGap = 12.0;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollUpdateNotification) {
                final idx =
                    (_controller.offset / (cardWidth + cardGap)).round();
                if (idx != _activeIndex) setState(() => _activeIndex = idx);
              }
              return false;
            },
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: cardGap),
              itemBuilder: (context, index) {
                final item = _items[index];
                return SizedBox(
                  width: cardWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image
                        Image.asset(
                          item.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: item.color,
                          ),
                        ),
                        // Dark gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                item.color.withOpacity(0.15),
                                item.color.withOpacity(0.85),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.badge.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Dots indicator
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _activeIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _activeIndex
                    ? const Color(0xFF006D56)
                    : const Color(0xFF006D56).withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE GRID  (4 columns, colored icon backgrounds)
// ═══════════════════════════════════════════════════════════════════════════

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.modules, required this.onOpen});

  final List<AppModule> modules;
  final ValueChanged<AppModule> onOpen;

  static const _serviceColors = [
    Color(0xFFE8F5E9), // green
    Color(0xFFE3F2FD), // blue
    Color(0xFFFCE4EC), // pink
    Color(0xFFFFF3E0), // orange
    Color(0xFFF3E5F5), // purple
    Color(0xFFE0F2F1), // teal
    Color(0xFFFFF8E1), // amber
    Color(0xFFE8EAF6), // indigo
  ];

  static const _serviceIconColors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFFF57F17),
    Color(0xFF283593),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (modules.isEmpty) {
      return Text(
        'Aucun service disponible pour le moment.',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final bgColor = isDark
            ? Colors.white.withOpacity(0.07)
            : _serviceColors[index % _serviceColors.length];
        final iconColor = _serviceIconColors[index % _serviceIconColors.length];

        return _ServiceTile(
          module: module,
          bgColor: bgColor,
          iconColor: iconColor,
          onTap: () => onOpen(module),
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.module,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  final AppModule module;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAsset = moduleIconAsset(
          moduleKey: module.moduleKey,
          iconKey: module.icon,
        ) !=
        null;
    final iconSize = hasAsset ? 30.0 : 26.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Icon container
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: ModuleIcon.forModule(
                module,
                size: iconSize,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            module.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
