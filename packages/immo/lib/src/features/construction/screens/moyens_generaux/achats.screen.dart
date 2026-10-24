import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/features/construction/models/material_request.model.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/request_details.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// Moyens généraux' "Achats" tab: validated material demandes to order, then
/// those ordered and delivered.
class AchatsScreen extends StatelessWidget {
  const AchatsScreen({super.key, required this.store});

  final ConstructionStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.requests.where((r) => r.isMaterial).toList();
        final toOrder = all.where((r) => r.isToOrder).toList()
          ..sort((a, b) => (a.validatedAt ?? a.createdAt ?? DateTime(0))
              .compareTo(b.validatedAt ?? b.createdAt ?? DateTime(0)));
        final ordered = all.where((r) => r.isOrdered).toList();
        final delivered = all.where((r) => r.isDelivered).toList();
        final budget = toOrder.fold<double>(0, (s, r) => s + (r.budget ?? 0));
        return ImmoTabPage(
          title: 'Achats',
          subtitle: 'Commandes aux fournisseurs',
          onRefresh: store.signedIn ? store.refresh : null,
          children: [
            ImmoStatRow(stats: [
              ImmoStat(label: 'À commander', value: '${toOrder.length}', icon: Icons.shopping_cart_outlined),
              ImmoStat(label: 'Budget à engager', value: formatFcfaShort(budget), icon: Icons.account_balance_wallet_outlined),
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
            else ...[
              const ImmoSectionTitle('À commander'),
              if (toOrder.isEmpty)
                const ImmoEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Rien à commander',
                  message: 'Les demandes validées par le superviseur apparaîtront ici.',
                )
              else
                for (final r in toOrder) _OrderTile(request: r, store: store),
              if (ordered.isNotEmpty) ...[
                const SizedBox(height: ImmoSpacing.md),
                const ImmoSectionTitle('Commandées'),
                for (final r in ordered) _OrderTile(request: r, store: store),
              ],
              if (delivered.isNotEmpty) ...[
                const SizedBox(height: ImmoSpacing.md),
                const ImmoSectionTitle('Livrées'),
                for (final r in delivered) _OrderTile(request: r, store: store),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.request, required this.store});

  final MaterialRequest request;
  final ConstructionStore store;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return ImmoListTile(
      icon: r.isToOrder
          ? Icons.shopping_cart_outlined
          : r.isOrdered
              ? Icons.local_shipping_outlined
              : Icons.task_alt_rounded,
      title: r.siteName ?? r.title,
      subtitle: [
        if (r.supplierName != null) r.supplierName!,
        if (r.budget != null && r.budget! > 0) formatFcfa(r.budget!),
        r.items.length == 1 ? '1 ligne' : '${r.items.length} lignes',
      ].join(' · '),
      // Those to order sit under "À commander" already
      trailing: r.isToOrder ? null : ImmoChip(label: r.statusLabel),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final supplier = await showImmoSheet<String>(
      context,
      title: request.title,
      builder: (_) => _OrderSheet(request: request, store: store),
    );
    if (supplier == null) return;
    messenger.showSnackBar(SnackBar(content: Text('Commande envoyée à $supplier')));
  }
}

/// The demande, and — while it is to order — the supplier to order it from.
/// Pops the supplier's name once ordered.
class _OrderSheet extends StatefulWidget {
  const _OrderSheet({required this.request, required this.store});

  final MaterialRequest request;
  final ConstructionStore store;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  final _instruction = TextEditingController();
  List<Supplier>? _suppliers;
  Supplier? _chosen;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.request.isToOrder) _loadSuppliers();
  }

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final r = await widget.store.suppliers();
    if (!mounted) return;
    setState(() {
      _suppliers = r.suppliers;
      _error = r.error;
      if (r.suppliers.length == 1) _chosen = r.suppliers.single;
    });
  }

  Future<void> _order() async {
    final supplier = _chosen;
    if (supplier == null) {
      setState(() => _error = 'Choisissez un fournisseur.');
      return;
    }
    final ok = await showImmoConfirm(
      context,
      title: 'Commander chez ${supplier.name} ?',
      message: 'La commande de ${widget.request.items.length} lignes sera envoyée au fournisseur, '
          'avec livraison au chantier.',
      confirmLabel: 'Commander',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final instruction = _instruction.text.trim();
    final error = await widget.store.order(
      widget.request,
      supplier,
      instruction: instruction.isEmpty ? null : instruction,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, supplier.name);
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
    final suppliers = _suppliers;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RequestDetails(request: r),
        if (r.isToOrder) ...[
          const SizedBox(height: ImmoSpacing.md),
          const ImmoFieldLabel('Fournisseur'),
          if (suppliers == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (suppliers.isEmpty && _error == null)
            Text('Aucun fournisseur enregistré.', style: TextStyle(fontSize: 13.5, color: b.muted))
          else
            for (final f in suppliers)
              ImmoListTile(
                icon: Icons.storefront_outlined,
                title: f.name,
                subtitle: [
                  if (f.specialties != null && f.specialties!.isNotEmpty) f.specialties!,
                  if (f.rating != null && f.rating! > 0) 'note ${f.rating}/5',
                ].join(' · '),
                trailing: Icon(
                  _chosen?.id == f.id ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: _chosen?.id == f.id ? b.primary : b.muted,
                ),
                onTap: _busy ? null : () => setState(() => _chosen = f),
              ),
          const SizedBox(height: ImmoSpacing.sm),
          const ImmoFieldLabel('Instruction de livraison (facultatif)'),
          TextField(
            controller: _instruction,
            enabled: !_busy,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: b.text),
            decoration: immoFieldDecoration(context, hintText: 'Par défaut : adresse du chantier'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          ],
          const SizedBox(height: ImmoSpacing.lg),
          FilledButton(
            onPressed: _busy ? null : _order,
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
                : Text(_chosen == null ? 'Commander' : 'Commander chez ${_chosen!.name}'),
          ),
        ],
      ],
    );
  }
}
