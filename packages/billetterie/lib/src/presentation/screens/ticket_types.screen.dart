import 'package:flutter/material.dart';

import 'package:billetterie/src/presentation/constants/billetterie.brand.dart';
import 'package:billetterie/src/data/models/billetterie.ticket.dart';
import 'package:billetterie/src/data/services/ticket_storage.service.dart';

class TicketTypesScreen extends StatefulWidget {
  const TicketTypesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TicketTypesScreen> createState() => _TicketTypesScreenState();
}

class _TicketTypesScreenState extends State<TicketTypesScreen> {
  final _storage = TicketStorageService();
  List<BilletterieTicketType> _types = const [];
  final _name = TextEditingController();
  final _price = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.listTicketTypes();
    if (!mounted) return;
    setState(() => _types = items);
  }

  Future<void> _addType() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_price.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    final type = BilletterieTicketType(
      id: 'type-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      scope: 'other',
      createdAt: DateTime.now().toIso8601String(),
      price: price,
      currency: 'XOF',
    );
    await _storage.upsertTicketType(type);
    _name.clear();
    _price.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text('Types de tickets'),
        backgroundColor: Colors.white,
        foregroundColor: BilletterieBrand.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom du type *')),
          TextField(
            controller: _price,
            decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _addType,
            style: FilledButton.styleFrom(backgroundColor: BilletterieBrand.primaryDark),
            child: const Text('Ajouter'),
          ),
          const SizedBox(height: 20),
          if (_types.isEmpty)
            Text('Aucun type. Créez Standard, VIP, Pass…', style: TextStyle(color: Colors.grey.shade600))
          else
            for (final t in _types)
              ListTile(
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(t.price != null ? '${t.price!.toStringAsFixed(0)} FCFA' : 'Sans prix'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _storage.deleteTicketType(t.id);
                    await _load();
                  },
                ),
              ),
        ],
      ),
    );
  }
}
