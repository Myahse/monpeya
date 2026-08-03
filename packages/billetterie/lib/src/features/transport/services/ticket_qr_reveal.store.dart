import 'package:shared_preferences/shared_preferences.dart';

import 'package:billetterie/src/core/constants/billetterie.prefs.dart';
import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';

/// Remembers which owned tickets have already had their QR scratched open.
class TicketQrRevealStore {
  TicketQrRevealStore();

  static String idFor(BilletterieTransportTicket ticket) {
    final code = ticket.ticketCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    return ticket.resolvedQrPayload;
  }

  Future<Set<String>> listRevealedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(BilletteriePrefs.qrRevealedTicketIds);
    return {...?raw};
  }

  Future<bool> isRevealed(BilletterieTransportTicket ticket) async {
    final ids = await listRevealedIds();
    return ids.contains(idFor(ticket));
  }

  Future<void> markRevealed(BilletterieTransportTicket ticket) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = {...?prefs.getStringList(BilletteriePrefs.qrRevealedTicketIds)};
    final id = idFor(ticket);
    if (ids.contains(id)) return;
    ids.add(id);
    await prefs.setStringList(
      BilletteriePrefs.qrRevealedTicketIds,
      ids.toList(growable: false),
    );
  }
}
