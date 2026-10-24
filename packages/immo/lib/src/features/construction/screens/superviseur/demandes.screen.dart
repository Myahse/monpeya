import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/features/construction/models/material_request.model.dart';
import 'package:immo/src/features/construction/models/metre.model.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/plan_view_3d.widget.dart';
import 'package:immo/src/features/construction/widgets/request_details.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// Superviseur's "Demandes" tab: requests to validate first, then those already handled.
class DemandesScreen extends StatelessWidget {
  const DemandesScreen({super.key, required this.store});

  final ConstructionStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.requests;
        final pending = all.where((r) => r.isPending).toList()
          ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        final handled = all.where((r) => !r.isPending).toList();
        final pendingBudget = pending.fold<double>(0, (s, r) => s + (r.budget ?? 0));
        return ImmoTabPage(
          title: 'Demandes',
          subtitle: 'Validation des demandes des chantiers',
          onRefresh: store.signedIn ? store.refresh : null,
          children: [
            ImmoStatRow(stats: [
              ImmoStat(label: 'À valider', value: '${pending.length}', icon: Icons.pending_actions_rounded),
              ImmoStat(label: 'Budget en attente', value: formatFcfaShort(pendingBudget), icon: Icons.account_balance_wallet_outlined),
            ]),
            const SizedBox(height: ImmoSpacing.lg),
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
                message: 'Connectez-vous à Mon Peya pour suivre vos chantiers.',
              )
            else if (store.error != null && all.isEmpty)
              ImmoEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Chargement impossible',
                message: store.error!,
                actionLabel: 'Réessayer',
                onAction: store.refresh,
              )
            else ...[
              const ImmoSectionTitle('À valider'),
              if (pending.isEmpty)
                const ImmoEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Rien à valider',
                  message: 'Les demandes des chefs de chantier apparaîtront ici.',
                )
              else
                for (final r in pending) _RequestTile(request: r, store: store),
              if (handled.isNotEmpty) ...[
                const SizedBox(height: ImmoSpacing.md),
                const ImmoSectionTitle('Traitées'),
                for (final r in handled) _RequestTile(request: r, store: store),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.store});

  final MaterialRequest request;
  final ConstructionStore store;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return ImmoListTile(
      icon: r.isPending
          ? Icons.pending_actions_rounded
          : r.isRefused
              ? Icons.block_rounded
              : Icons.task_alt_rounded,
      danger: r.isRefused,
      title: r.siteName ?? r.title,
      subtitle: [
        if (r.budget != null && r.budget! > 0) formatFcfa(r.budget!),
        r.items.length == 1 ? '1 ligne' : '${r.items.length} lignes',
        if (r.createdAt != null) formatDate(r.createdAt!),
      ].join(' · '),
      // Pending ones sit under "À valider" already; the chip tells the others apart
      trailing: r.isPending ? null : ImmoChip(label: r.statusLabel),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showImmoSheet<bool>(
      context,
      title: request.title,
      builder: (_) => _RequestSheet(request: request, store: store),
    );
    if (result == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text(result ? 'Demande validée — transmise aux moyens généraux' : 'Demande refusée'),
    ));
  }
}

/// Lines, budget and context of a demande; validate or refuse it while pending.
/// Pops `true` when validated, `false` when refused.
class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.request, required this.store});

  final MaterialRequest request;
  final ConstructionStore store;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _reason = TextEditingController();
  bool _refusing = false;
  bool _busy = false;
  String? _error;

  /// The drawn métré the demande came from, once loaded.
  SiteMetre? _metre;

  @override
  void initState() {
    super.initState();
    widget.store.metreOfRequest(widget.request).then((m) {
      if (mounted && m != null) setState(() => _metre = m);
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  /// The house the quantities were measured on, turned with a finger; read-only.
  List<Widget> _plan3d(ImmoRentalPalette b, SiteMetre m) {
    final i = m.input;
    return [
      const SizedBox(height: ImmoSpacing.md),
      const ImmoFieldLabel('Vue 3D'),
      Text(
        '${[
          if (m.updatedAt != null) 'Métré du ${formatDate(m.updatedAt!)}',
          i.levels == 1 ? '1 niveau' : '${i.levels} niveaux',
          'murs de ${formatNumber(i.wallHeight)} m',
        ].join(' · ')}. Glissez pour tourner la maison.',
        style: TextStyle(fontSize: 13.5, color: b.muted, height: 1.4),
      ),
      const SizedBox(height: ImmoSpacing.sm),
      Container(
        padding: const EdgeInsets.all(ImmoSpacing.sm),
        decoration: ImmoDecor.card(context),
        child: PlanView3D.ofInput(i),
      ),
    ];
  }

  Future<void> _validate() async {
    final ok = await showImmoConfirm(
      context,
      title: 'Valider la demande ?',
      message: 'Elle passera aux moyens généraux, qui passeront commande auprès des fournisseurs.',
      confirmLabel: 'Valider',
    );
    if (!ok || !mounted) return;
    await _decide(validate: true);
  }

  Future<void> _refuse() async {
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Indiquez le motif du refus.');
      return;
    }
    await _decide(validate: false, reason: _reason.text.trim());
  }

  Future<void> _decide({required bool validate, String? reason}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.store.decide(widget.request, validate: validate, reason: reason);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, validate);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final r = widget.request;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RequestDetails(request: r),
        if (_metre case final m?) ..._plan3d(b, m),
        if (r.isPending) ...[
          const SizedBox(height: ImmoSpacing.md),
          if (_refusing) ...[
            const ImmoFieldLabel('Motif du refus'),
            TextField(
              controller: _reason,
              enabled: !_busy,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: b.text),
              decoration: immoFieldDecoration(context, hintText: 'Ex. Quantité de fer trop élevée'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          ],
          const SizedBox(height: ImmoSpacing.md),
          if (_refusing)
            FilledButton(
              onPressed: _busy ? null : _refuse,
              style: FilledButton.styleFrom(
                backgroundColor: b.danger,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: _busy ? _spinner() : const Text('Confirmer le refus'),
            )
          else ...[
            FilledButton(
              onPressed: _busy ? null : _validate,
              style: FilledButton.styleFrom(
                backgroundColor: b.primary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: _busy ? _spinner() : const Text('Valider la demande'),
            ),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _refusing = true),
              style: TextButton.styleFrom(foregroundColor: b.danger),
              child: const Text('Refuser'),
            ),
          ],
        ],
      ],
    );
  }

  static Widget _spinner() => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
