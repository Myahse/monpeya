import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../billetterie_brand.dart';
import '../models/billetterie_ticket.dart';
import '../services/billetterie_host_payment.dart';
import '../services/ticket_storage_service.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key, required this.onBack, required this.onSaved});

  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _storage = TicketStorageService();
  List<BilletterieTicketType> _types = const [];
  String? _typeId;
  final _holder = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _amount = TextEditingController();
  String? _previewQr;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _holder.dispose();
    _phone.dispose();
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final types = await _storage.listTicketTypes();
    if (!mounted) return;
    setState(() {
      _types = types;
      _typeId = types.isNotEmpty ? types.first.id : null;
    });
  }

  void _updatePreview() {
    final type = _types.cast<BilletterieTicketType?>().firstWhere((t) => t?.id == _typeId, orElse: () => null);
    if (type == null || _holder.text.trim().isEmpty) {
      setState(() => _previewQr = null);
      return;
    }
    final amount = double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? type.price;
    setState(() {
      _previewQr = buildTicketQrPayload(
        ticketId: 'draft',
        typeId: type.id,
        typeName: type.name,
        holderName: _holder.text.trim(),
        holderPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        amount: amount,
        currency: 'XOF',
        createdAt: DateTime.now().toIso8601String(),
      );
    });
  }

  Future<void> _save() async {
    final type = _types.cast<BilletterieTicketType?>().firstWhere((t) => t?.id == _typeId, orElse: () => null);
    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créez d\'abord un type de ticket.')),
      );
      return;
    }
    if (_holder.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du porteur requis.')),
      );
      return;
    }

    final id = makeTicketId('ticket');
    final now = DateTime.now().toIso8601String();
    final amount = double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? type.price;
    final qrPayload = buildTicketQrPayload(
      ticketId: id,
      typeId: type.id,
      typeName: type.name,
      holderName: _holder.text.trim(),
      holderPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      amount: amount,
      currency: 'XOF',
      createdAt: now,
    );

    await _storage.addTicket(
      BilletterieTicket(
        id: id,
        typeId: type.id,
        typeName: type.name,
        holderName: _holder.text.trim(),
        holderPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        amount: amount,
        currency: 'XOF',
        createdAt: now,
        qrPayload: qrPayload,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket créé')),
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text('Créer un ticket'),
        backgroundColor: Colors.white,
        foregroundColor: BilletterieBrand.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_types.isEmpty)
            Text('Aucun type — créez-en un dans Types de tickets.', style: TextStyle(color: Colors.grey.shade700))
          else
            DropdownButtonFormField<String>(
              initialValue: _typeId,
              decoration: const InputDecoration(labelText: 'Type *'),
              items: [
                for (final t in _types)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) {
                setState(() => _typeId = v);
                _updatePreview();
              },
            ),
          TextField(
            controller: _holder,
            decoration: const InputDecoration(labelText: 'Nom du porteur *'),
            onChanged: (_) => _updatePreview(),
          ),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Téléphone'),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _updatePreview(),
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note'),
            onChanged: (_) => _updatePreview(),
          ),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updatePreview(),
          ),
          if (_previewQr != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BilletterieBrand.border),
                ),
                child: QrImageView(data: _previewQr!, size: 180),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(backgroundColor: BilletterieBrand.primaryDark, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
