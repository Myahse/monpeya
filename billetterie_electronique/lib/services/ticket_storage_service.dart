import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/billetterie_prefs.dart';
import '../models/billetterie_ticket.dart';

class TicketStorageService {
  Future<List<BilletterieTicketType>> listTicketTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(BilletteriePrefs.ticketTypes);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => BilletterieTicketType.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<BilletterieTicketType> upsertTicketType(BilletterieTicketType type) async {
    final all = await listTicketTypes();
    final idx = all.indexWhere((t) => t.id == type.id);
    final updated = idx >= 0
        ? [...all.sublist(0, idx), type, ...all.sublist(idx + 1)]
        : [type, ...all];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      BilletteriePrefs.ticketTypes,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    return type;
  }

  Future<void> deleteTicketType(String typeId) async {
    final all = await listTicketTypes();
    final updated = all.where((t) => t.id != typeId).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      BilletteriePrefs.ticketTypes,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<BilletterieTicket>> listTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(BilletteriePrefs.tickets);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => BilletterieTicket.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addTicket(BilletterieTicket ticket) async {
    final all = await listTickets();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      BilletteriePrefs.tickets,
      jsonEncode([ticket, ...all].map((e) => e.toJson()).toList()),
    );
  }

  Future<BilletterieTicket?> updateTicket(
    String ticketId,
    BilletterieTicket Function(BilletterieTicket current) patch,
  ) async {
    final all = await listTickets();
    final idx = all.indexWhere((t) => t.id == ticketId);
    if (idx < 0) return null;
    final next = patch(all[idx]);
    final updated = [...all.sublist(0, idx), next, ...all.sublist(idx + 1)];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      BilletteriePrefs.tickets,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    return next;
  }
}
