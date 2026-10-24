import 'package:flutter/material.dart';

import 'package:immo/src/features/collection/services/collection.store.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';

/// Collection home — Location layout in the Collection accent.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.onOpenProperties,
    required this.onOpenCollection,
  });

  final CollectionStore store;
  final VoidCallback onOpenProperties;
  final VoidCallback onOpenCollection;

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    final name = (session.displayName ?? '').trim();

    return ImmoHeaderPage(
      eyebrow: 'Mr Immo Collection',
      title: name.isEmpty ? 'Bonjour' : 'Bonjour, $name',
      subtitle: 'Gestion locative & recouvrement',
      trailing: const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final properties = store.properties;
          final payments = store.payments;
          final now = DateTime.now();
          final late = payments.where((p) => p.isLate(now)).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final collected = payments
              .where((p) => p.isPaid &&
                  p.paidAt != null &&
                  p.paidAt!.month == now.month &&
                  p.paidAt!.year == now.year)
              .fold<double>(0, (sum, p) => sum + p.amount);
          final units = properties.fold<int>(0, (s, p) => s + (p.unitCount ?? 1));

          return RefreshIndicator(
            onRefresh: store.refresh,
            color: Theme.of(context).colorScheme.primary,
            notificationPredicate: (_) => store.signedIn,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  ImmoStat(label: 'Impayés', value: '${late.length}', icon: Icons.warning_amber_rounded),
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
                    onTap: onOpenProperties,
                  ),
                  ImmoAction(
                    title: 'Recouvrement',
                    subtitle: 'Échéances et relances',
                    icon: Icons.receipt_long_rounded,
                    onTap: onOpenCollection,
                  ),
                ]),
                const SizedBox(height: ImmoSpacing.lg),
                const ImmoSectionTitle('À relancer'),
                if (!store.loaded)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (!store.signedIn)
                  const ImmoEmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Connexion requise',
                    message: 'Connectez-vous à Mon Peya pour suivre vos loyers.',
                  )
                else if (late.isEmpty)
                  const ImmoEmptyState(
                    icon: Icons.verified_outlined,
                    title: 'Tout est à jour',
                    message: 'Aucune échéance impayée. Les retards de loyer apparaîtront ici.',
                  )
                else
                  for (final p in late.take(5))
                    ImmoListTile(
                      icon: Icons.schedule_rounded,
                      danger: true,
                      title: p.tenantName ?? formatFcfa(p.amount),
                      subtitle: [
                        if (p.tenantName != null) formatFcfa(p.amount),
                        'Échéance du ${formatDate(p.dueDate)}',
                      ].join(' · '),
                      onTap: onOpenCollection,
                    ),
              ]),
            ),
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
