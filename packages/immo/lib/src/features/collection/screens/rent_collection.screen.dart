import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/config/collection_api.endpoints.dart';
import 'package:immo/src/features/collection/models/payment.model.dart';
import 'package:immo/src/features/collection/models/tenant.model.dart';
import 'package:immo/src/features/collection/services/collection.store.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// Loyers — late and upcoming rents, tenants without a schedule, and what was
/// collected. Tap a rent to mark it as paid.
class RentCollectionScreen extends StatelessWidget {
  const RentCollectionScreen({
    super.key,
    required this.store,
    this.propertyId,
    this.onClearProperty,
  });

  final CollectionStore store;
  final String? propertyId;
  final VoidCallback? onClearProperty;

  /// Rents due within this window are listed as "À venir"; later ones are counted.
  static const _upcomingWindow = Duration(days: 31);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final all = propertyId == null
            ? store.payments
            : store.payments.where((p) => p.propertyId == propertyId).toList();
        final due = all.where((p) => !p.isPaid).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final late = due.where((p) => p.isLate(now)).toList();
        final upcoming = due
            .where((p) => !p.isLate(now) && p.dueDate.isBefore(now.add(_upcomingWindow)))
            .toList();
        final later = due.length - late.length - upcoming.length;
        final paid = all.where((p) => p.isPaid).toList()
          ..sort((a, b) => (b.paidAt ?? b.dueDate).compareTo(a.paidAt ?? a.dueDate));
        final collectedThisMonth = paid
            .where((p) => p.paidAt != null &&
                p.paidAt!.month == now.month &&
                p.paidAt!.year == now.year)
            .fold<double>(0, (s, p) => s + p.amount);
        final toSchedule = store.unscheduledTenants
            .where((t) => propertyId == null || t.propertyId == propertyId)
            .toList();
        final propertyName = propertyId == null
            ? null
            : store.properties
                .where((p) => p.id == propertyId)
                .map((p) => p.name)
                .firstOrNull;

        return ImmoTabPage(
          title: 'Recouvrement',
          subtitle: 'Échéances, relances et encaissements',
          onRefresh: store.signedIn ? store.refresh : null,
          children: [
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
            else ...[
              if (store.error != null) ...[
                ImmoEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Chargement impossible',
                  message: store.error!,
                  actionLabel: 'Réessayer',
                  onAction: store.refresh,
                ),
                const SizedBox(height: ImmoSpacing.lg),
              ],
              ImmoStatRow(stats: [
                ImmoStat(
                  label: 'En retard',
                  value: formatFcfa(late.fold<double>(0, (s, p) => s + p.amount)),
                  icon: Icons.warning_amber_rounded,
                ),
                ImmoStat(
                  label: 'Encaissé ce mois',
                  value: formatFcfa(collectedThisMonth),
                  icon: Icons.task_alt_rounded,
                ),
              ]),
              const SizedBox(height: ImmoSpacing.lg),
              if (propertyId != null)
                ImmoSectionTitle(
                  propertyName ?? 'Bien',
                  action: 'Tous les biens',
                  onAction: onClearProperty,
                ),
              if (late.isNotEmpty) ...[
                const ImmoSectionTitle('En retard'),
                for (final p in late) _dueTile(context, p, late: true),
              ],
              const ImmoSectionTitle('À venir'),
              if (late.isEmpty && upcoming.isEmpty)
                const ImmoEmptyState(
                  icon: Icons.event_available_rounded,
                  title: 'Aucune échéance',
                  message: 'Les loyers à encaisser et les retards apparaîtront ici.',
                )
              else if (upcoming.isEmpty)
                const ImmoListTile(
                  icon: Icons.event_available_rounded,
                  title: 'Rien ce mois-ci',
                  subtitle: 'Aucun loyer à encaisser dans les 30 prochains jours.',
                )
              else
                for (final p in upcoming) _dueTile(context, p, late: false),
              if (later > 0) _LaterNote(count: later),
              if (toSchedule.isNotEmpty) ...[
                const SizedBox(height: ImmoSpacing.md),
                const ImmoSectionTitle('Échéanciers à créer'),
                for (final t in toSchedule)
                  ImmoListTile(
                    icon: Icons.event_note_rounded,
                    title: t.name,
                    subtitle: [
                      if (t.propertyName != null) t.propertyName!,
                      t.canSchedule
                          ? '${formatFcfa(t.rent!)} ${_frequencyLabel(t.frequency)}'
                          : 'Bail incomplet',
                    ].join(' · '),
                    onTap: () => _confirmSchedule(context, t),
                  ),
              ],
              if (paid.isNotEmpty) ...[
                const SizedBox(height: ImmoSpacing.md),
                const ImmoSectionTitle('Encaissements'),
                for (final p in paid.take(10))
                  ImmoListTile(
                    icon: Icons.check_circle_outline_rounded,
                    title: '${formatFcfa(p.amount)} · ${p.tenantName ?? 'Locataire'}',
                    subtitle: [
                      'Payé le ${formatDate(p.paidAt ?? p.dueDate)}',
                      if (p.method != null && p.method!.isNotEmpty) p.method!,
                    ].join(' · '),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _dueTile(BuildContext context, CollectionPayment p, {required bool late}) {
    return ImmoListTile(
      icon: late ? Icons.warning_amber_rounded : Icons.schedule_rounded,
      danger: late,
      title: p.tenantName ?? formatFcfa(p.amount),
      subtitle: [
        if (p.tenantName != null) formatFcfa(p.amount),
        late
            ? 'En retard depuis le ${formatDate(p.dueDate)}'
            : 'À payer le ${formatDate(p.dueDate)}',
      ].join(' · '),
      onTap: () => _openMarkPaid(context, p),
    );
  }

  Future<void> _openMarkPaid(BuildContext context, CollectionPayment p) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = await showImmoSheet<bool>(
      context,
      title: 'Encaisser le loyer',
      builder: (_) => _MarkPaidForm(store: store, payment: p),
    );
    if (done == true) {
      messenger.showSnackBar(
        SnackBar(content: Text('Loyer de ${p.tenantName ?? 'locataire'} encaissé')),
      );
    }
  }

  Future<void> _confirmSchedule(BuildContext context, CollectionTenant t) async {
    final messenger = ScaffoldMessenger.of(context);
    final danger = ImmoBrand.rentalOf(context).danger;
    if (!t.canSchedule) {
      messenger.showSnackBar(SnackBar(
        content: const Text('Bail incomplet : loyer ou dates du bail manquants.'),
        backgroundColor: danger,
      ));
      return;
    }
    final ok = await showImmoConfirm(
      context,
      title: 'Créer l’échéancier ?',
      message: '${formatFcfa(t.rent!)} ${_frequencyLabel(t.frequency)} pour ${t.name}, '
          'du ${formatDate(t.leaseStart!)} au ${formatDate(t.leaseEnd!)}.',
      confirmLabel: 'Créer',
    );
    if (!ok) return;
    final error = await store.generateSchedule(t);
    messenger.showSnackBar(error == null
        ? SnackBar(content: Text('Échéancier créé pour ${t.name}'))
        : SnackBar(content: Text(error), backgroundColor: danger));
  }

  static String _frequencyLabel(String? frequency) => switch (frequency?.toLowerCase()) {
        'daily' => 'par jour',
        'yearly' => 'par an',
        _ => 'par mois',
      };
}

class _LaterNote extends StatelessWidget {
  const _LaterNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: ImmoSpacing.sm),
      child: Text(
        count == 1 ? '1 échéance plus tard' : '$count échéances plus tard',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: b.muted),
      ),
    );
  }
}

/// Method + optional reference, then confirm. Pops `true` once the rent is marked paid.
class _MarkPaidForm extends StatefulWidget {
  const _MarkPaidForm({required this.store, required this.payment});

  final CollectionStore store;
  final CollectionPayment payment;

  @override
  State<_MarkPaidForm> createState() => _MarkPaidFormState();
}

class _MarkPaidFormState extends State<_MarkPaidForm> {
  final _reference = TextEditingController();
  String _method = CollectionPaymentMethods.all.first;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await widget.store.markPaid(
      widget.payment,
      method: _method,
      reference: _reference.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  static IconData _methodIcon(String method) => switch (method) {
        'Espèces' => Icons.payments_outlined,
        'Mobile money' => Icons.phone_iphone_rounded,
        'Peya Pay' => Icons.account_balance_wallet_outlined,
        _ => Icons.account_balance_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final p = widget.payment;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          formatFcfa(p.amount),
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: b.text),
        ),
        const SizedBox(height: 4),
        Text(
          [
            p.tenantName ?? 'Locataire',
            if (p.propertyName != null) p.propertyName!,
            'échéance du ${formatDate(p.dueDate)}',
          ].join(' · '),
          style: TextStyle(fontSize: 13.5, color: b.muted, height: 1.4),
        ),
        const SizedBox(height: ImmoSpacing.lg),
        const ImmoFieldLabel('Mode de paiement'),
        for (final m in CollectionPaymentMethods.all)
          ImmoListTile(
            icon: _methodIcon(m),
            title: m,
            trailing: Icon(
              m == _method
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: m == _method ? b.primary : b.muted,
            ),
            onTap: _submitting ? null : () => setState(() => _method = m),
          ),
        const SizedBox(height: ImmoSpacing.sm),
        const ImmoFieldLabel('Référence (facultatif)'),
        TextField(
          controller: _reference,
          enabled: !_submitting,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: b.text),
          decoration: immoFieldDecoration(
            context,
            hintText: 'N° de reçu ou de transaction',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
        ],
        const SizedBox(height: ImmoSpacing.lg),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: b.primary,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirmer l’encaissement'),
        ),
      ],
    );
  }
}
