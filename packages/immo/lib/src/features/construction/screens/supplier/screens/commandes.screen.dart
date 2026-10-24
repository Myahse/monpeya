import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/features/construction/models/material_request.model.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/construction_segment.style.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// Supplier's "Commandes" tab: orders to deliver, then those delivered.
class SupplierOrdersScreen extends StatefulWidget {
  const SupplierOrdersScreen({super.key, required this.store});

  final ConstructionStore store;

  @override
  State<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends State<SupplierOrdersScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.store.supplierOrders == null) widget.store.loadSupplierOrders();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final orders = store.supplierOrders;
        final all = orders ?? const <SupplierOrder>[];
        final toDeliver = all.where((o) => o.isToDeliver).toList()
          ..sort((a, b) => (a.orderedAt ?? DateTime(0)).compareTo(b.orderedAt ?? DateTime(0)));
        final delivered = all.where((o) => o.isDelivered).toList();
        final now = DateTime.now();
        final deliveredThisMonth = delivered
            .where((o) => o.deliveredAt != null && o.deliveredAt!.month == now.month && o.deliveredAt!.year == now.year)
            .fold<double>(0, (s, o) => s + (o.total ?? 0));
        return ImmoTabPage(
          title: 'Commandes',
          subtitle: 'Commandes reçues et livraisons',
          onRefresh: store.signedIn ? store.loadSupplierOrders : null,
          children: [
            ImmoStatRow(stats: [
              ImmoStat(label: 'À livrer', value: '${toDeliver.length}', icon: Icons.local_shipping_outlined),
              ImmoStat(label: 'Livrées', value: '${delivered.length}', icon: Icons.task_alt_rounded),
              ImmoStat(label: 'Livré ce mois', value: formatFcfaCompact(deliveredThisMonth), icon: Icons.trending_up_rounded),
            ]),
            const SizedBox(height: ImmoSpacing.lg),
            if (!store.loaded || (store.signedIn && orders == null))
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
                message: 'Connectez-vous pour voir les commandes reçues.',
              )
            else if (store.supplierError != null && all.isEmpty)
              ImmoEmptyState(
                icon: Icons.storefront_outlined,
                title: 'Commandes indisponibles',
                message: store.supplierError!,
                actionLabel: 'Réessayer',
                onAction: store.loadSupplierOrders,
              )
            else ...[
              const ImmoSectionTitle('À livrer'),
              if (toDeliver.isEmpty)
                const ImmoEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucune commande à livrer',
                  message: 'Les commandes des chantiers s’afficheront ici dès réception.',
                )
              else
                for (final o in toDeliver) _OrderTile(order: o, store: store),
              if (delivered.isNotEmpty) ...[
                const SizedBox(height: ImmoSpacing.md),
                const ImmoSectionTitle('Livrées'),
                for (final o in delivered) _OrderTile(order: o, store: store),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.store});

  final SupplierOrder order;
  final ConstructionStore store;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return ImmoListTile(
      icon: o.isToDeliver ? Icons.local_shipping_outlined : Icons.task_alt_rounded,
      title: o.siteName ?? 'Chantier',
      subtitle: [
        if (o.total != null && o.total! > 0) formatFcfa(o.total!),
        o.lines.length == 1 ? '1 ligne' : '${o.lines.length} lignes',
        if (o.isDelivered && o.deliveredAt != null)
          'livrée le ${formatDate(o.deliveredAt!)}'
        else if (o.isOnItsWay && o.expectedOn != null)
          'prévue le ${formatDate(o.expectedOn!)}'
        else if (o.orderedAt != null)
          'du ${formatDate(o.orderedAt!)}',
      ].join(' · '),
      // Those still to send sit under "À livrer" already; the others say how far they got
      trailing: o.isToDeliver && !o.isOnItsWay ? null : ImmoChip(label: o.statusLabel),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = await showImmoSheet<_OrderStep>(
      context,
      title: order.siteName ?? 'Commande',
      builder: (_) => _OrderSheet(order: order, store: store),
    );
    switch (done) {
      case _OrderStep.shipped:
        messenger.showSnackBar(const SnackBar(content: Text('Commande en route')));
      case _OrderStep.delivered:
        messenger.showSnackBar(const SnackBar(content: Text('Livraison confirmée — en attente de réception sur le chantier')));
      case null:
        break;
    }
  }
}

enum _OrderStep { shipped, delivered }

/// Where to deliver, what, and — while to deliver — setting off, then the delivery.
/// Pops the step taken.
class _OrderSheet extends StatefulWidget {
  const _OrderSheet({required this.order, required this.store});

  final SupplierOrder order;
  final ConstructionStore store;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Expected on site in this many days.
  int _inDays = 1;

  /// The busy action is setting off (its button spins), not the delivery.
  bool _shipping = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _ship() async {
    setState(() {
      _busy = true;
      _shipping = true;
      _error = null;
    });
    final today = DateTime.now();
    final error = await widget.store.shipOrder(
      widget.order,
      expectedOn: DateTime(today.year, today.month, today.day + _inDays),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, _OrderStep.shipped);
      return;
    }
    setState(() {
      _busy = false;
      _shipping = false;
      _error = error;
    });
  }

  Future<void> _deliver() async {
    final ok = await showImmoConfirm(
      context,
      title: 'Confirmer la livraison ?',
      message: 'Toutes les lignes seront marquées livrées. Le chef de chantier fera ensuite la réception sur place.',
      confirmLabel: 'Confirmer',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final comment = _comment.text.trim();
    final error = await widget.store.confirmDelivery(widget.order, comment: comment.isEmpty ? null : comment);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, _OrderStep.delivered);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  /// White on a filled button; [color] on a text button.
  static Widget _spinner([Color color = Colors.white]) => SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final o = widget.order;
    final muted = TextStyle(fontSize: 13.5, color: b.muted, height: 1.4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: ImmoChip(label: o.statusLabel)),
        const SizedBox(height: 12),
        Text(
          [
            if (o.number != null) 'Commande n° ${o.number}',
            if (o.orderedAt != null) 'du ${formatDate(o.orderedAt!)}',
            if (o.isOnItsWay && o.shippedAt != null) 'en route le ${formatDate(o.shippedAt!)}',
            if (o.isOnItsWay && o.expectedOn != null) 'arrivée prévue le ${formatDate(o.expectedOn!)}',
            if (o.isDelivered && o.deliveredAt != null) 'livrée le ${formatDate(o.deliveredAt!)}',
            if (o.receivedAt != null)
              '${o.isShort ? 'réception partielle' : 'réceptionnée'} le ${formatDate(o.receivedAt!)}',
          ].join(' · '),
          style: muted,
        ),
        if (o.instruction != null && o.instruction!.isNotEmpty) ...[
          const SizedBox(height: ImmoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_outlined, color: b.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(o.instruction!, style: TextStyle(color: b.text, height: 1.4))),
            ],
          ),
        ],
        const SizedBox(height: ImmoSpacing.md),
        for (final l in o.lines)
          ImmoListTile(
            icon: Icons.inventory_2_outlined,
            title: l.label,
            subtitle: [
              l.quantityLabel,
              if (o.isShort && l.delivered < l.ordered) 'reçu ${quantityWithUnit(l.delivered, l.unit)}',
              if (l.amount != null && l.amount! > 0) formatFcfa(l.amount!),
            ].join(' · '),
          ),
        if (o.total != null && o.total! > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Montant : ${formatFcfa(o.total!)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: b.text),
          ),
        ],
        if (o.isToDeliver && !o.isOnItsWay) ...[
          const SizedBox(height: ImmoSpacing.md),
          const ImmoFieldLabel('Arrivée prévue au chantier'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Aujourd’hui')),
              ButtonSegment(value: 1, label: Text('Demain')),
              ButtonSegment(value: 2, label: Text('Après-demain')),
            ],
            selected: {_inDays},
            showSelectedIcon: false,
            onSelectionChanged: _busy ? null : (s) => setState(() => _inDays = s.first),
            style: constructionSegmentStyle(b),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          ],
          const SizedBox(height: ImmoSpacing.lg),
          FilledButton(
            onPressed: _busy ? null : _ship,
            style: FilledButton.styleFrom(
              backgroundColor: b.primary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: _busy && _shipping ? _spinner() : const Text('Mettre en route'),
          ),
          TextButton(
            onPressed: _busy ? null : _deliver,
            style: TextButton.styleFrom(foregroundColor: b.primary),
            child: _busy && !_shipping ? _spinner(b.primary) : const Text('Confirmer la livraison'),
          ),
        ],
        if (o.isOnItsWay) ...[
          const SizedBox(height: ImmoSpacing.md),
          const ImmoFieldLabel('Commentaire (facultatif)'),
          TextField(
            controller: _comment,
            enabled: !_busy,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: b.text),
            decoration: immoFieldDecoration(context, hintText: 'Ex. Déchargé au portail, reçu par le gardien'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          ],
          const SizedBox(height: ImmoSpacing.lg),
          FilledButton(
            onPressed: _busy ? null : _deliver,
            style: FilledButton.styleFrom(
              backgroundColor: b.primary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: _busy ? _spinner() : const Text('Confirmer la livraison'),
          ),
        ],
      ],
    );
  }
}
