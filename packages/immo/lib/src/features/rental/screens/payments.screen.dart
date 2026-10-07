import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/services/rental.payment.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';

const _monthsFr = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _formatAmount(double amount) {
  final s = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${buf.toString()} FCFA';
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')} ${_monthsFr[date.month - 1]} ${date.year}';
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<RentalPayment> _payments = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final api = RentalSessionScope.of(context).api;
      final items = await api.payments.fetchPayments();
      if (!mounted) return;
      setState(() => _payments = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _payments = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final monthlyTotal = _payments
        .where((p) {
          final d = p.paidAt;
          if (d == null) return false;
          final now = DateTime.now();
          return d.month == now.month && d.year == now.year;
        })
        .fold<double>(0, (sum, p) => sum + p.amount);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: b.bg,
        child: Column(
          children: [
            RentalGradientPageHeader(
              title: 'Mes paiements',
              subtitle: 'Suivez vos loyers',
              paddingTop: 60,
              paddingBottom: 40,
              leading: widget.onBack == null
                  ? null
                  : IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    ),
            ),
            Expanded(
              child: RentalWhiteSheet(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: RentalTheme.green,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      RentalTheme.spacingLg,
                      RentalTheme.spacingLg,
                      RentalTheme.spacingLg,
                      RentalTheme.scrollBottomPad,
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              value: '${_payments.length}',
                              label: 'Total paiements',
                              green: false,
                            ),
                          ),
                          const SizedBox(width: RentalTheme.spacingMd),
                          Expanded(
                            child: _StatCard(
                              value: _formatAmount(monthlyTotal),
                              label: 'Ce mois-ci',
                              green: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RentalTheme.spacingLg),
                      Text(
                        'Historique des paiements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: b.text,
                        ),
                      ),
                      const SizedBox(height: RentalTheme.spacingMd),
                      if (_payments.isEmpty)
                        const _PaymentsEmptyState()
                      else
                        for (final p in _payments) _PaymentCard(payment: p),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.green,
  });

  final String value;
  final String label;
  final bool green;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(RentalTheme.spacingMd),
      decoration: BoxDecoration(
        color: green ? RentalTheme.green : b.searchFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: green ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: green ? Colors.white : RentalTheme.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: green ? const Color(0xE6FFFFFF) : b.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final RentalPayment payment;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: RentalTheme.spacingMd),
      padding: const EdgeInsets.all(RentalTheme.spacingMd),
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: b.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: b.isDark ? 0.35 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RentalTheme.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.credit_card, color: RentalTheme.green, size: 22),
              ),
              const SizedBox(width: RentalTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatAmount(payment.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: RentalTheme.green,
                      ),
                    ),
                    Text(
                      _formatDate(payment.paidAt),
                      style: TextStyle(fontSize: 13, color: b.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: RentalTheme.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Payé',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RentalTheme.green,
                  ),
                ),
              ),
            ],
          ),
          if (payment.comment != null && payment.comment!.isNotEmpty) ...[
            const SizedBox(height: RentalTheme.spacingSm),
            Text(
              payment.comment!,
              style: TextStyle(
                fontSize: 13,
                color: b.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentsEmptyState extends StatelessWidget {
  const _PaymentsEmptyState();

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.credit_card_rounded, size: 64, color: RentalTheme.of(context).muted),
          const SizedBox(height: RentalTheme.spacingMd),
          Text(
            'Aucun paiement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: b.text),
          ),
          const SizedBox(height: RentalTheme.spacingSm),
          Text(
            'Votre historique de paiements apparaîtra ici',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: b.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
