import 'package:flutter/material.dart';

import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/data/models/peyapay_api.exception.dart';
import 'package:peyapay/src/data/models/peyapay_carte.models.dart';
import 'package:peyapay/src/data/services/peyapay_carte_api.service.dart';
import 'package:peyapay/src/presentation/client_flow/peyapay_carte_order.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_add_money.screen.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_prepaid_card_flip.widget.dart';

/// PeyaPay prepaid card — wired to Mon Peya `/v1/carte/*` proxy.
class PeyapayPrepaidCardScreen extends StatefulWidget {
  const PeyapayPrepaidCardScreen({
    super.key,
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  State<PeyapayPrepaidCardScreen> createState() =>
      _PeyapayPrepaidCardScreenState();
}

class _PeyapayPrepaidCardScreenState extends State<PeyapayPrepaidCardScreen> {
  static const _balanceGreen = Color(0xFF006D56);

  final _api = PeyapayHostBridge.carteApi ?? PeyapayCarteApiService();

  bool _showDetails = false;
  bool _loading = true;
  bool _busyAction = false;
  String? _error;

  PeyapayCarteMontant? _montant;
  PeyapayCarteCurrent? _current;
  PeyapayCarteBalance? _balance;

  bool get _frozen =>
      _current?.statusCarte == 5 || (_current?.active == false && _current?.hasActiveCard == true);

  int? get _cardBalance => _balance?.soldeCarte;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final montant = await _api.montant();
      final current = await _api.current();
      PeyapayCarteBalance? balance;
      if (current.isActiveOrDelivered || current.active) {
        try {
          balance = await _api.balance();
        } on PeyapayApiException {
          // Balance may not be ready yet — keep UI usable.
        }
      }
      if (!mounted) return;
      setState(() {
        _montant = montant;
        _current = current;
        _balance = balance;
        _loading = false;
      });
    } on PeyapayApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _back() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _openOrder() async {
    final price = _montant?.montantCarte ?? 0;
    final ordered = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PeyapayCarteOrderScreen(
          montantCarte: price,
          onOrdered: _reload,
        ),
      ),
    );
    if (ordered == true) await _reload();
  }

  Future<void> _toggleFreeze() async {
    setState(() => _busyAction = true);
    try {
      if (_frozen) {
        await _api.activate();
      } else {
        await _api.inactive();
      }
      await _reload();
    } on PeyapayApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _showShippingCode() async {
    setState(() => _busyAction = true);
    try {
      final result = await _api.shippingCode();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Code livreur'),
          content: Text(
            result.codeLivraison ?? '—',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ],
        ),
      );
      await _reload();
    } on PeyapayApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final panel = isDark ? cs.surfaceContainerHighest : const Color(0xFFF3F4F6);
    final current = _current;

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
                  onPressed: _loading ? null : _reload,
                  icon: Icon(Icons.refresh_rounded, color: ink),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _reload, ink: ink)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PeyapayPrepaidCardFlip(frozen: _frozen),
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
                            if (current != null && current.statusCarteLabel != null) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(current: current, ink: ink),
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
                                    _cardBalance != null ? 'Solde carte' : 'Carte PeyaPay',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _cardBalance != null
                                        ? (_showDetails
                                            ? '${formatFrMoneySigned(_cardBalance!)} XOF'
                                            : '*****')
                                        : (_montant != null
                                            ? '${formatFrMoneySigned(_montant!.montantCarte)} XOF'
                                            : '—'),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _cardBalance != null
                                        ? 'Solde Onafriq'
                                        : 'Prix carte physique',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (current != null &&
                                !current.hasActiveCard &&
                                current.canBuyNewCard) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _busyAction ? null : _openOrder,
                                icon: const Icon(Icons.shopping_bag_outlined),
                                label: const Text('Commander ma carte'),
                              ),
                            ],
                            if (current?.isDelivering == true) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _busyAction ? null : _showShippingCode,
                                icon: const Icon(Icons.local_shipping_outlined),
                                label: const Text('Voir le code livreur'),
                              ),
                            ],
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
                            if (current?.isActiveOrDelivered == true || current?.active == true) ...[
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
                                onTap: _busyAction ? () {} : _toggleFreeze,
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.current, required this.ink});

  final PeyapayCarteCurrent current;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (current.statusCarteLabel != null) current.statusCarteLabel!,
      if (current.libelleVille != null) current.libelleVille!,
      if (current.libelleCommune != null) current.libelleCommune!,
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        parts.join(' · '),
        style: TextStyle(fontWeight: FontWeight.w700, color: ink, fontSize: 13),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.ink,
  });

  final String message;
  final VoidCallback onRetry;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: ink, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: ink)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
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
