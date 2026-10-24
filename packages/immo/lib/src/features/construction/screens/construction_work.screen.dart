import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';
import 'package:immo/src/features/construction/models/construction.site.dart';
import 'package:immo/src/features/construction/models/material_request.model.dart';
import 'package:immo/src/features/construction/navigation/construction.tab.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/request_details.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

/// "Commandes" (supplier) or "Chantiers" (site manager) tab.
class ConstructionWorkScreen extends StatelessWidget {
  const ConstructionWorkScreen({
    super.key,
    required this.role,
    required this.store,
    this.onOpenMetre,
  });

  final ConstructionRole role;
  final ConstructionStore store;

  /// Opens the métré (dimensions → materials → demande) of a chantier.
  final ValueChanged<ConstructionSite>? onOpenMetre;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      key: ValueKey(role),
      listenable: store,
      builder: (context, _) {
        final sites = store.sites;
        final now = DateTime.now();
        final ongoing = sites.where((s) => s.active).toList();
        final paused = sites.where((s) => s.paused).toList();
        final done = sites.where((s) => s.finished).toList();
        return ImmoTabPage(
          title: 'Chantiers',
          subtitle: 'Suivi de vos chantiers',
          onRefresh: store.signedIn ? store.refresh : null,
          children: [
            ImmoStatRow(stats: [
              ImmoStat(label: 'En cours', value: '${ongoing.length}', icon: Icons.timelapse_rounded),
              ImmoStat(label: 'En pause', value: '${paused.length}', icon: Icons.pause_circle_outline),
              ImmoStat(label: 'Terminés', value: '${done.length}', icon: Icons.task_alt_rounded),
            ]),
            const SizedBox(height: ImmoSpacing.lg),
            const ImmoSectionTitle('Mes chantiers'),
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
            else if (store.error != null && sites.isEmpty)
              ImmoEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Chargement impossible',
                message: store.error!,
                actionLabel: 'Réessayer',
                onAction: store.refresh,
              )
            else if (sites.isEmpty)
              const ImmoEmptyState(
                icon: Icons.foundation_rounded,
                title: 'Aucun chantier',
                message: 'Ajoutez un chantier pour suivre l’avancement, l’équipe et les achats.',
              )
            else
              for (final s in [...ongoing, ...paused, ...done])
                ImmoListTile(
                  icon: s.handedOver
                      ? Icons.key_rounded
                      : s.finished
                          ? Icons.task_alt_rounded
                          : Icons.foundation_rounded,
                  title: s.name,
                  subtitle: _siteLine(s, now),
                  trailing: ImmoChip(label: s.statusLabel),
                  onTap: () => _openSite(context, s),
                ),
          ],
        );
      },
    );
  }

  static String _siteLine(ConstructionSite s, DateTime now) {
    final elapsed = s.elapsed(now);
    return [
      if (s.city != null && s.city!.isNotEmpty) s.city!,
      if (s.handedOver && s.rentalOpenedAt != null)
        'En location depuis le ${formatDate(s.rentalOpenedAt!)}'
      else if (s.finished && s.actualEnd != null)
        'Terminé le ${formatDate(s.actualEnd!)}'
      else if (s.plannedEnd != null)
        'Fin prévue le ${formatDate(s.plannedEnd!)}',
      if (!s.finished && elapsed != null) '${(elapsed * 100).round()} % du délai',
    ].join(' · ');
  }

  Future<void> _openSite(BuildContext context, ConstructionSite site) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showImmoSheet<_SitePick>(
      context,
      title: site.name,
      builder: (_) => _SiteSheet(store: store, site: site, withMetre: onOpenMetre != null),
    );
    switch (picked) {
      case (_SiteAction.handedOver, _):
        messenger.showSnackBar(SnackBar(
          content: Text('${site.name} est passé en location — visible dans Mr Immo Location'),
        ));
      case (_SiteAction.metre, _):
        onOpenMetre?.call(site);
      case (_SiteAction.request, final MaterialRequest request):
        if (context.mounted) await _openRequest(context, request);
      case _:
        break;
    }
  }

  Future<void> _openRequest(BuildContext context, MaterialRequest request) async {
    final messenger = ScaffoldMessenger.of(context);
    final full = await showImmoSheet<bool>(
      context,
      title: request.title,
      builder: (_) => _ReceptionSheet(request: request, store: store),
    );
    if (full == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text(full ? 'Réception enregistrée — la demande est clôturée' : 'Réception enregistrée — le manque est signalé'),
    ));
  }
}

enum _SiteAction { handedOver, metre, request }

/// What the chantier sheet closed on; [_SiteAction.request] carries the demande to open.
typedef _SitePick = (_SiteAction, MaterialRequest?);

/// Chantier facts, its métré, and the hand-over to Mr Immo Location while it is not done yet.
class _SiteSheet extends StatefulWidget {
  const _SiteSheet({required this.store, required this.site, required this.withMetre});

  final ConstructionStore store;
  final ConstructionSite site;
  final bool withMetre;

  @override
  State<_SiteSheet> createState() => _SiteSheetState();
}

class _SiteSheetState extends State<_SiteSheet> {
  final _rent = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _rent.dispose();
    super.dispose();
  }

  Future<void> _handover() async {
    final rentText = _rent.text.replaceAll(RegExp(r'\s'), '');
    final rent = rentText.isEmpty ? null : double.tryParse(rentText);
    if (rentText.isNotEmpty && (rent == null || rent <= 0)) {
      setState(() => _error = 'Saisissez un loyer valide, ou laissez vide.');
      return;
    }
    final ok = await showImmoConfirm(
      context,
      title: 'Passer en location ?',
      message: '« ${widget.site.name} » sera clôturé et ajouté à vos biens '
          'disponibles dans Mr Immo Location. Cette action est définitive.',
      confirmLabel: 'Passer en location',
    );
    if (!ok || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await widget.store.handover(widget.site, monthlyRent: rent);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, (_SiteAction.handedOver, null));
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  /// The icons the other roles' lists give each step.
  static IconData _requestIcon(MaterialRequest r) => switch (r) {
        _ when r.isRefused => Icons.block_rounded,
        _ when r.isPending => Icons.pending_actions_rounded,
        _ when r.isToOrder => Icons.shopping_cart_outlined,
        _ when r.isAwaitingReception => Icons.fact_check_outlined,
        _ when r.isOrdered => Icons.local_shipping_outlined,
        _ when r.isDelivered => Icons.task_alt_rounded,
        _ => Icons.assignment_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final s = widget.site;
    final facts = <(IconData, String)>[
      if (s.address != null && s.address!.isNotEmpty)
        (Icons.place_outlined, [s.address!, if (s.city != null) s.city!].join(', ')),
      if (s.surfaceM2 != null) (Icons.square_foot_rounded, '${s.surfaceM2!.round()} m²'),
      if (s.budget != null) (Icons.account_balance_wallet_outlined, 'Budget ${formatFcfa(s.budget!)}'),
      if (s.startDate != null && s.plannedEnd != null)
        (Icons.event_outlined, 'Du ${formatDate(s.startDate!)} au ${formatDate(s.plannedEnd!)}'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: ImmoChip(label: s.statusLabel)),
        const SizedBox(height: 12),
        for (final (icon, text) in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(icon, color: b.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: TextStyle(color: b.text))),
              ],
            ),
          ),
        const SizedBox(height: ImmoSpacing.sm),
        ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            final requests = widget.store.requests.where((r) => r.siteId == s.id && r.isMaterial).toList();
            if (requests.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ImmoFieldLabel('Demandes de matériaux'),
                for (final r in requests)
                  ImmoListTile(
                    icon: _requestIcon(r),
                    danger: r.isRefused,
                    // The chantier is this sheet's own: "Matériaux — Villa…" reads "Matériaux"
                    title: r.title.replaceFirst(' — ${s.name}', ''),
                    subtitle: [
                      if (r.budget != null && r.budget! > 0) formatFcfa(r.budget!),
                      r.items.length == 1 ? '1 ligne' : '${r.items.length} lignes',
                      if (r.isOnItsWay && r.expectedOn != null)
                        'prévue le ${formatDate(r.expectedOn!)}'
                      else if (r.createdAt != null)
                        formatDate(r.createdAt!),
                    ].join(' · '),
                    trailing: ImmoChip(label: r.statusLabel),
                    onTap: _submitting ? null : () => Navigator.pop(context, (_SiteAction.request, r)),
                  ),
                const SizedBox(height: ImmoSpacing.sm),
              ],
            );
          },
        ),
        if (s.handedOver)
          ImmoListTile(
            icon: Icons.key_rounded,
            title: 'Passé en location',
            subtitle: s.rentalOpenedAt == null
                ? 'Ce bien est géré dans Mr Immo Location.'
                : 'Le ${formatDate(s.rentalOpenedAt!)} · géré dans Mr Immo Location',
          )
        else ...[
          if (widget.withMetre) ...[
            ImmoListTile(
              icon: Icons.calculate_outlined,
              title: 'Métré & matériaux',
              subtitle: 'Agglos, ciment, sable, fer… et la demande',
              onTap: _submitting ? null : () => Navigator.pop(context, (_SiteAction.metre, null)),
            ),
            const SizedBox(height: ImmoSpacing.sm),
          ],
          const ImmoFieldLabel('Loyer mensuel (facultatif)'),
          TextField(
            controller: _rent,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
            style: TextStyle(color: b.text),
            decoration: immoFieldDecoration(
              context,
              hintText: 'Ex. 250 000',
              suffixText: 'FCFA',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          ],
          const SizedBox(height: ImmoSpacing.lg),
          FilledButton(
            onPressed: _submitting ? null : _handover,
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
                : const Text('Terminer et passer en location'),
          ),
        ],
      ],
    );
  }
}

/// A demande of the chantier; once delivered, the chef de chantier says what arrived.
/// Pops `true` when all of it did, `false` when something is missing.
class _ReceptionSheet extends StatefulWidget {
  const _ReceptionSheet({required this.request, required this.store});

  final MaterialRequest request;
  final ConstructionStore store;

  @override
  State<_ReceptionSheet> createState() => _ReceptionSheetState();
}

class _ReceptionSheetState extends State<_ReceptionSheet> {
  /// One field per ordered line, keyed by its order line.
  late final Map<String, TextEditingController> _counted = {
    for (final item in widget.request.items)
      ?item.orderLineId: TextEditingController(text: '${item.delivered ?? item.quantity}'),
  };
  final _comment = TextEditingController();
  bool _counting = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _counted.values) {
      c.dispose();
    }
    _comment.dispose();
    super.dispose();
  }

  Future<void> _receiveAll() async {
    final ok = await showImmoConfirm(
      context,
      title: 'Tout est arrivé ?',
      message: 'Toutes les quantités commandées seront notées reçues et la demande sera clôturée.',
      confirmLabel: 'Confirmer',
    );
    if (!ok || !mounted) return;
    await _send(const {}, full: true);
  }

  Future<void> _receiveCounted() async {
    final counted = <String, int>{};
    for (final item in widget.request.items) {
      final field = _counted[item.orderLineId];
      if (field == null) continue;
      final n = int.tryParse(field.text.replaceAll(RegExp(r'\s'), ''));
      if (n == null || n < 0 || n > item.quantity) {
        setState(() => _error = 'Saisissez entre 0 et ${item.quantityLabel} pour « ${item.label} ».');
        return;
      }
      counted[item.orderLineId!] = n;
    }
    final full = widget.request.items.every((i) => counted[i.orderLineId] == null || counted[i.orderLineId] == i.quantity);
    setState(() => _error = null);
    final ok = await showImmoConfirm(
      context,
      title: 'Confirmer la réception ?',
      message: full
          ? 'Toutes les quantités commandées sont arrivées : la demande sera clôturée.'
          : 'Les quantités saisies seront notées reçues et le manque sera signalé.',
      confirmLabel: 'Confirmer',
    );
    if (!ok || !mounted) return;
    await _send(counted, full: full);
  }

  Future<void> _send(Map<String, int> counted, {required bool full}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final comment = _comment.text.trim();
    final error = await widget.store.receiveDelivery(
      widget.request,
      counted: counted,
      comment: comment.isEmpty ? null : comment,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, full);
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
        if (r.isAwaitingReception) ...[
          const SizedBox(height: ImmoSpacing.md),
          if (_counting) ...[
            Text(
              'Saisissez ce qui est réellement arrivé sur le chantier.',
              style: TextStyle(fontSize: 13.5, color: b.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final item in r.items)
              if (_counted[item.orderLineId] case final field?) ...[
                ImmoFieldLabel('${item.label} — commande : ${item.quantityLabel}'),
                TextField(
                  controller: field,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: b.text),
                  decoration: immoFieldDecoration(
                    context,
                    hintText: 'Quantité reçue',
                    suffixText: item.unit == null ? null : unitPlural(item.unit!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            const ImmoFieldLabel('Commentaire (facultatif)'),
            TextField(
              controller: _comment,
              enabled: !_busy,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: b.text),
              decoration: immoFieldDecoration(context, hintText: 'Ex. 20 sacs de ciment manquants'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          ],
          const SizedBox(height: ImmoSpacing.md),
          FilledButton(
            onPressed: _busy ? null : (_counting ? _receiveCounted : _receiveAll),
            style: FilledButton.styleFrom(
              backgroundColor: b.primary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_counting ? 'Confirmer la réception' : 'Tout est arrivé'),
          ),
          if (!_counting && _counted.isNotEmpty)
            TextButton(
              onPressed: _busy ? null : () => setState(() => _counting = true),
              style: TextButton.styleFrom(foregroundColor: b.primary),
              child: const Text('Il manque quelque chose'),
            ),
        ],
      ],
    );
  }
}
