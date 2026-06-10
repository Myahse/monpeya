import 'package:flutter/material.dart';

import '../billetterie_brand.dart';
import '../models/billetterie_event.dart';
import '../models/billetterie_ticket.dart';
import '../services/ticket_storage_service.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({
    super.key,
    required this.onBack,
    required this.onTicketTap,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onTicketTap;

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final _storage = TicketStorageService();
  List<BilletterieTicket> _tickets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.listTickets();
    if (!mounted) return;
    setState(() => _tickets = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text('Mes tickets'),
        backgroundColor: Colors.white,
        foregroundColor: BilletterieBrand.text,
      ),
      body: _tickets.isEmpty
          ? Center(child: Text('Aucun ticket.', style: TextStyle(color: Colors.grey.shade600)))
          : RefreshIndicator(
              onRefresh: _load,
              color: BilletterieBrand.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tickets.length,
                itemBuilder: (context, i) {
                  final t = _tickets[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: BilletterieBrand.primarySoft,
                        child: Icon(Icons.confirmation_number, color: BilletterieBrand.primaryDark),
                      ),
                      title: Text(t.typeName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${t.holderName}${t.amount != null ? ' • ${formatBilletterieCurrency(t.amount!.toInt())}' : ''}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.onTicketTap(t.id),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
