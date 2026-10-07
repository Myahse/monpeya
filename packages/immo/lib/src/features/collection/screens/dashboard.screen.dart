import 'package:flutter/material.dart';

import 'package:immo/src/features/collection/models/payment.model.dart';
import 'package:immo/src/features/collection/models/property.model.dart';
import 'package:immo/src/features/collection/services/payment.service.dart';
import 'package:immo/src/features/collection/services/property.service.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';

/// Collection home — Location layout in the Collection accent.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenProperties,
    required this.onOpenCollection,
  });

  final VoidCallback onOpenProperties;
  final VoidCallback onOpenCollection;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<(List<CollectionProperty>, List<CollectionPayment>)> _data =
      Future.wait([
    CollectionPropertyService().fetchProperties(),
    CollectionPaymentService().fetchPayments(),
  ]).then((r) => (
        r[0] as List<CollectionProperty>,
        r[1] as List<CollectionPayment>,
      ));

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    final name = (session.displayName ?? '').trim();

    return ImmoHeaderPage(
      eyebrow: 'Mr Immo Collection',
      title: name.isEmpty ? 'Bonjour' : 'Bonjour, $name',
      subtitle: 'Gestion locative & recouvrement',
      trailing: const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
      body: FutureBuilder(
        future: _data,
        builder: (context, snap) {
          final properties = snap.data?.$1 ?? const <CollectionProperty>[];
          final payments = snap.data?.$2 ?? const <CollectionPayment>[];
          final now = DateTime.now();
          final unpaid = payments.where((p) => p.paidAt == null).toList();
          final late = unpaid.where((p) => p.dueDate.isBefore(now)).length;
          final collected = payments
              .where((p) => p.paidAt != null &&
                  p.paidAt!.month == now.month &&
                  p.paidAt!.year == now.year)
              .fold<double>(0, (sum, p) => sum + p.amount);
          final units = properties.fold<int>(0, (s, p) => s + (p.unitCount ?? 1));

          return ListView(
            padding: EdgeInsets.fromLTRB(
              ImmoSpacing.lg,
              ImmoSpacing.lg,
              ImmoSpacing.lg,
              ImmoPillNavBar.contentBottomPadding(context),
            ),
            children: ImmoStagger.wrap([
              ImmoStatRow(stats: [
                ImmoStat(label: 'Biens', value: '${properties.length}', icon: Icons.apartment_rounded),
                ImmoStat(label: 'Lots', value: '$units', icon: Icons.door_front_door_outlined),
                ImmoStat(label: 'Impayés', value: '$late', icon: Icons.warning_amber_rounded),
              ]),
              const SizedBox(height: 12),
              _CollectedBanner(amount: collected),
              const SizedBox(height: ImmoSpacing.lg),
              const ImmoSectionTitle('Services'),
              ImmoActionGrid(actions: [
                ImmoAction(
                  title: 'Biens',
                  subtitle: 'Parc, lots et locataires',
                  icon: Icons.apartment_rounded,
                  onTap: widget.onOpenProperties,
                ),
                ImmoAction(
                  title: 'Recouvrement',
                  subtitle: 'Échéances et relances',
                  icon: Icons.receipt_long_rounded,
                  onTap: widget.onOpenCollection,
                ),
              ]),
              const SizedBox(height: ImmoSpacing.lg),
              const ImmoSectionTitle('À relancer'),
              if (unpaid.isEmpty)
                const ImmoEmptyState(
                  icon: Icons.verified_outlined,
                  title: 'Tout est à jour',
                  message: 'Aucune échéance impayée. Les retards de loyer apparaîtront ici.',
                )
              else
                for (final p in unpaid.take(5))
                  ImmoListTile(
                    icon: Icons.schedule_rounded,
                    title: formatFcfa(p.amount),
                    subtitle: 'Échéance du ${formatDate(p.dueDate)}',
                    onTap: widget.onOpenCollection,
                  ),
            ]),
          );
        },
      ),
    );
  }
}

class _CollectedBanner extends StatelessWidget {
  const _CollectedBanner({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ImmoDecor.card(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encaissé ce mois',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: amount),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    formatFcfa(v),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.savings_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }
}
