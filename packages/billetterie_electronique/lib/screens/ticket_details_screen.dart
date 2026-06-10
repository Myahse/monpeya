import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../billetterie_brand.dart';
import '../models/billetterie_event.dart';
import '../models/billetterie_ticket.dart';
import '../services/billetterie_host_payment.dart';
import '../services/ticket_storage_service.dart';

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({super.key, required this.ticketId, required this.onBack});

  final String ticketId;
  final VoidCallback onBack;

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final _storage = TicketStorageService();
  BilletterieTicket? _ticket;
  bool _fetchComplete = false;

  static const _maxTopUp = 6000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _storage.listTickets();
    if (!mounted) return;
    setState(() {
      _ticket = all.cast<BilletterieTicket?>().firstWhere(
            (t) => t?.id == widget.ticketId,
            orElse: () => null,
          );
      _fetchComplete = true;
    });
  }

  Future<void> _topUp() async {
    final ticket = _ticket;
    if (ticket == null) return;

    final current = ticket.amount?.toInt() ?? 0;
    if (current >= _maxTopUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plafond atteint (${formatBilletterieCurrency(_maxTopUp)}).')),
      );
      return;
    }

    const topUpAmount = 1000;
    final ok = await BilletterieHostPayment.requestPayment(
      context: context,
      amount: topUpAmount,
      recipientName: 'Billetterie',
      reference: ticket.id,
      label: 'Recharge ticket • ${ticket.typeName}',
    );
    if (!ok || !mounted) return;

    final nextAmount = (current + topUpAmount).toDouble();
    final updated = await _storage.updateTicket(ticket.id, (t) {
      final qr = buildTicketQrPayload(
        ticketId: t.id,
        typeId: t.typeId,
        typeName: t.typeName,
        holderName: t.holderName,
        holderPhone: t.holderPhone,
        note: t.note,
        amount: nextAmount,
        currency: t.currency ?? 'XOF',
        createdAt: t.createdAt,
      );
      return BilletterieTicket(
        id: t.id,
        typeId: t.typeId,
        typeName: t.typeName,
        holderName: t.holderName,
        holderPhone: t.holderPhone,
        note: t.note,
        amount: nextAmount,
        currency: t.currency,
        createdAt: t.createdAt,
        qrPayload: qr,
      );
    });

    if (!mounted) return;
    setState(() => _ticket = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket rechargé')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)),
        body: Center(
          child: Text(
            _fetchComplete ? 'Ticket introuvable' : '',
            style: const TextStyle(color: BilletterieBrand.muted),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text('Ticket'),
        backgroundColor: Colors.white,
        foregroundColor: BilletterieBrand.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BilletterieBrand.border),
              ),
              child: QrImageView(data: ticket.qrPayload, size: 220),
            ),
          ),
          const SizedBox(height: 20),
          Text(ticket.typeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Porteur: ${ticket.holderName}'),
          if (ticket.holderPhone != null) Text('Tél: ${ticket.holderPhone}'),
          if (ticket.note != null) Text('Note: ${ticket.note}'),
          if (ticket.amount != null) ...[
            const SizedBox(height: 8),
            Text('Solde: ${formatBilletterieCurrency(ticket.amount!.toInt())}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _topUp,
            icon: const Icon(Icons.add),
            label: Text('Recharger (+1000 FCFA, max ${formatBilletterieCurrency(_maxTopUp)})'),
          ),
        ],
      ),
    );
  }
}
