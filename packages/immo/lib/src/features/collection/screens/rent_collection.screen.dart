import 'package:flutter/material.dart';

import 'package:immo/src/features/collection/models/payment.model.dart';
import 'package:immo/src/features/collection/services/payment.service.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class RentCollectionScreen extends StatefulWidget {
  const RentCollectionScreen({super.key, this.propertyId});

  final String? propertyId;

  @override
  State<RentCollectionScreen> createState() => _RentCollectionScreenState();
}

class _RentCollectionScreenState extends State<RentCollectionScreen> {
  late Future<List<CollectionPayment>> _payments = _load();

  Future<List<CollectionPayment>> _load() =>
      CollectionPaymentService().fetchPayments(propertyId: widget.propertyId);

  @override
  void didUpdateWidget(RentCollectionScreen old) {
    super.didUpdateWidget(old);
    if (old.propertyId != widget.propertyId) _payments = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _payments,
      builder: (context, snap) {
        final list = snap.data ?? const <CollectionPayment>[];
        final due = list.where((p) => p.paidAt == null).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final paid = list.where((p) => p.paidAt != null).toList();
        final dueTotal = due.fold<double>(0, (s, p) => s + p.amount);
        final paidTotal = paid.fold<double>(0, (s, p) => s + p.amount);
        final now = DateTime.now();

        return ImmoTabPage(
          title: 'Recouvrement',
          subtitle: 'Échéances, relances et encaissements',
          children: [
            ImmoStatRow(stats: [
              ImmoStat(label: 'À encaisser', value: formatFcfa(dueTotal), icon: Icons.schedule_rounded),
              ImmoStat(label: 'Encaissé', value: formatFcfa(paidTotal), icon: Icons.task_alt_rounded),
            ]),
            const SizedBox(height: ImmoSpacing.lg),
            const ImmoSectionTitle('Échéances'),
            if (due.isEmpty)
              const ImmoEmptyState(
                icon: Icons.event_available_rounded,
                title: 'Aucune échéance',
                message: 'Les loyers à encaisser et les retards apparaîtront ici.',
              )
            else
              for (final p in due)
                ImmoListTile(
                  icon: p.dueDate.isBefore(now)
                      ? Icons.warning_amber_rounded
                      : Icons.schedule_rounded,
                  danger: p.dueDate.isBefore(now),
                  title: formatFcfa(p.amount),
                  subtitle: p.dueDate.isBefore(now)
                      ? 'En retard depuis le ${formatDate(p.dueDate)}'
                      : 'À payer le ${formatDate(p.dueDate)}',
                ),
            if (paid.isNotEmpty) ...[
              const SizedBox(height: ImmoSpacing.md),
              const ImmoSectionTitle('Encaissements'),
              for (final p in paid)
                ImmoListTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: formatFcfa(p.amount),
                  subtitle: 'Payé le ${formatDate(p.paidAt!)}',
                ),
            ],
          ],
        );
      },
    );
  }
}
