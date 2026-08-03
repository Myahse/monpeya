import 'package:flutter/material.dart';

import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/presentation/screens/peyapay_add_money.screen.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_prepaid_card_flip.widget.dart';

/// PeyaPay prepaid card home — virtual card preview + quick actions.
class PeyapayPrepaidCardScreen extends StatefulWidget {
  const PeyapayPrepaidCardScreen({
    super.key,
    this.onClose,
  });

  /// Used when shown as a PeyaPay home slide overlay (preferred).
  final VoidCallback? onClose;

  @override
  State<PeyapayPrepaidCardScreen> createState() =>
      _PeyapayPrepaidCardScreenState();
}

class _PeyapayPrepaidCardScreenState extends State<PeyapayPrepaidCardScreen> {
  static const _balanceGreen = Color(0xFF006D56);

  bool _showDetails = false;
  bool _frozen = false;

  static const _cardBalance = 125000;

  void _back() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final panel = isDark ? cs.surfaceContainerHighest : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.viewPaddingOf(context).top + 28,
              left: 8,
              right: 12,
              bottom: 4,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _back,
                  icon: Icon(Icons.arrow_back_rounded, color: ink),
                ),
                Expanded(
                  child: Text(
                    'Carte prépayée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showDetails = !_showDetails),
                  icon: Icon(
                    _showDetails
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PeyapayPrepaidCardFlip(
                    frozen: _frozen,
                  ),
                  if (_frozen) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.ac_unit_rounded,
                            color: Color(0xFFE65100),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Carte gelée — les paiements sont temporairement bloqués.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: _balanceGreen,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde carte',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showDetails
                              ? '${formatFrMoneySigned(_cardBalance)} XOF'
                              : '*****',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PeyaPay prépayée',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    panel: panel,
                    ink: ink,
                    muted: muted,
                    icon: Icons.add_rounded,
                    iconColor: const Color(0xFF1A9E09),
                    iconBg: const Color.fromRGBO(26, 158, 9, 0.18),
                    title: 'Recharger la carte',
                    subtitle: 'Alimenter depuis votre solde PeyaPay',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PeyapayAddMoneyScreen(
                            cardType: 'VISA',
                            bankName: 'Carte prépayée Mon Peya',
                            cardLastFour: '4387',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    panel: panel,
                    ink: ink,
                    muted: muted,
                    icon: _frozen
                        ? Icons.lock_open_rounded
                        : Icons.ac_unit_rounded,
                    iconColor: const Color(0xFFE65100),
                    iconBg: const Color.fromRGBO(230, 81, 0, 0.14),
                    title: _frozen ? 'Dégeler la carte' : 'Geler la carte',
                    subtitle: _frozen
                        ? 'Réactiver les paiements immédiatement'
                        : 'Bloquer temporairement les paiements',
                    onTap: () => setState(() => _frozen = !_frozen),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    panel: panel,
                    ink: ink,
                    muted: muted,
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF1565C0),
                    iconBg: const Color.fromRGBO(21, 101, 192, 0.14),
                    title: 'Historiques carte',
                    subtitle: 'Bientôt disponible',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historique carte : bientôt.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.panel,
    required this.ink,
    required this.muted,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color panel;
  final Color ink;
  final Color muted;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
