import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:sim/src/data/models/sim_assurance_card.model.dart';

/// Cartes SIM enregistrées localement (JSON dans SharedPreferences).
class SimAssuranceCardStore {
  SimAssuranceCardStore._();

  static const _prefsKey = 'sim_assurance_cards';

  static Future<List<SimAssuranceCardRecord>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final cards = <SimAssuranceCardRecord>[];
      for (final item in decoded) {
        if (item is Map) {
          cards.add(SimAssuranceCardRecord.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      cards.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return cards;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> upsert(SimAssuranceCardRecord record) async {
    final cards = await loadAll();
    final next = <SimAssuranceCardRecord>[];
    var replaced = false;

    for (final existing in cards) {
      if (existing.souscriptionId == record.souscriptionId ||
          existing.numeroPolice == record.numeroPolice) {
        next.add(record);
        replaced = true;
      } else {
        next.add(existing);
      }
    }
    if (!replaced) next.insert(0, record);

    await _write(next);
  }

  static Future<void> _write(List<SimAssuranceCardRecord> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = cards.map((c) => c.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }
}
