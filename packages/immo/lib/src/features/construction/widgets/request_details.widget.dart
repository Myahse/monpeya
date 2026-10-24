import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/features/construction/models/material_request.model.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// What a demande asks for, as every role reads it in its sheet: status, when,
/// lines and budget, its delivery once ordered, the reason once refused.
class RequestDetails extends StatelessWidget {
  const RequestDetails({super.key, required this.request});

  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final r = request;
    final muted = TextStyle(fontSize: 13.5, color: b.muted, height: 1.4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: ImmoChip(label: r.statusLabel)),
        const SizedBox(height: 12),
        Text(
          [
            if (r.siteName != null && !r.title.contains(r.siteName!)) r.siteName!,
            if (r.createdAt != null) 'Demandée le ${formatDate(r.createdAt!)}',
            if (r.urgencyLabel != null) 'urgence ${r.urgencyLabel}',
          ].join(' · '),
          style: muted,
        ),
        if (r.justification != null && r.justification!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r.justification!, style: muted),
        ],
        const SizedBox(height: ImmoSpacing.md),
        for (final item in r.items)
          ImmoListTile(
            icon: Icons.inventory_2_outlined,
            title: item.label,
            subtitle: [
              item.quantityLabel,
              if (r.isShort && item.delivered != null && item.delivered! < item.quantity)
                'reçu ${quantityWithUnit(item.delivered!, item.unit)}',
              if (item.amount != null && item.amount! > 0) formatFcfa(item.amount!),
            ].join(' · '),
          ),
        if (r.budget != null && r.budget! > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Budget estimé : ${formatFcfa(r.budget!)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: b.text),
          ),
        ],
        if (r.supplierName != null || r.isOrdered || r.isDelivered) ...[
          const SizedBox(height: ImmoSpacing.md),
          const ImmoFieldLabel('Suivi'),
          for (final (done, text) in _steps(r))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: done ? b.primary : b.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: TextStyle(color: done ? b.text : b.muted))),
                ],
              ),
            ),
          if (r.receptionComment != null && r.receptionComment!.isNotEmpty)
            Text('« ${r.receptionComment} »', style: muted),
        ],
        if (r.isRefused && r.description != null && r.description!.contains('Motif du refus')) ...[
          const SizedBox(height: ImmoSpacing.sm),
          Text(
            r.description!.substring(r.description!.indexOf('Motif du refus')),
            style: TextStyle(fontSize: 13.5, color: b.danger, height: 1.4),
          ),
        ],
      ],
    );
  }

  /// From the order to the check on site, each step done or still to come.
  static List<(bool, String)> _steps(MaterialRequest r) {
    final delivered = r.isDelivered || r.deliveredAt != null;
    final checked = r.receivedAt != null || r.isReceived || r.isShort;
    return [
      (
        true,
        [
          [
            r.supplierName == null ? 'Commandée' : 'Commandée chez ${r.supplierName}',
            if (r.orderedAt != null) 'le ${formatDate(r.orderedAt!)}',
          ].join(' '),
          if (r.orderNumber != null) 'n° ${r.orderNumber}',
        ].join(' · '),
      ),
      // A supplier who delivered without setting off first skips this one
      if (r.shippedAt != null || !delivered)
        (
          r.shippedAt != null,
          [
            r.shippedAt == null ? 'En route' : 'En route le ${formatDate(r.shippedAt!)}',
            if (r.expectedOn != null) 'arrivée prévue le ${formatDate(r.expectedOn!)}',
          ].join(' · '),
        ),
      (delivered, r.deliveredAt == null ? 'Livrée' : 'Livrée le ${formatDate(r.deliveredAt!)}'),
      (
        checked,
        [
          r.isShort ? 'Réception partielle' : checked ? 'Réceptionnée' : 'Réception par le chef de chantier',
          if (r.receivedAt != null) 'le ${formatDate(r.receivedAt!)}',
        ].join(' '),
      ),
    ];
  }
}
