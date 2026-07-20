import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:billetterie/src/core/constants/billetterie.prefs.dart';
import 'package:billetterie/src/features/transport/services/billetterie_local_notifications.service.dart';

class BilletterieNotification {
  const BilletterieNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.type = 'info',
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String type;

  BilletterieNotification copyWith({bool? read}) {
    return BilletterieNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
      type: type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'type': type,
      };

  factory BilletterieNotification.fromJson(Map<String, dynamic> json) {
    return BilletterieNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      read: json['read'] == true,
      type: json['type']?.toString() ?? 'info',
    );
  }
}

/// Local billetterie notification inbox (persisted).
class BilletterieNotificationStore {
  BilletterieNotificationStore();

  Future<List<BilletterieNotification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(BilletteriePrefs.notifications);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => BilletterieNotification.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save(List<BilletterieNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      BilletteriePrefs.notifications,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<BilletterieNotification>> add(
    BilletterieNotification notification,
  ) async {
    final current = await load();
    final next = [notification, ...current];
    await _save(next);
    return next;
  }

  Future<List<BilletterieNotification>> markRead(String id) async {
    final current = await load();
    final next = [
      for (final item in current)
        item.id == id ? item.copyWith(read: true) : item,
    ];
    await _save(next);
    return next;
  }

  Future<List<BilletterieNotification>> markAllRead() async {
    final current = await load();
    final next = [for (final item in current) item.copyWith(read: true)];
    await _save(next);
    return next;
  }

  Future<int> unreadCount() async {
    final items = await load();
    return items.where((e) => !e.read).length;
  }

  /// Convenience: ticket purchase notification 
  Future<void> notifyTicketPurchased({
    required String ticketCode,
    String? orderRef,
    String? routeLabel,
  }) async {
    final order = orderRef?.trim();
    final route = routeLabel?.trim();
    final bodyParts = <String>[
      if (route != null && route.isNotEmpty) route,
      if (order != null && order.isNotEmpty) 'Ref. $order',
      'Code $ticketCode',
    ];
    await add(
      BilletterieNotification(
        id: 'purchase-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Billet achete',
        body: bodyParts.join(' · '),
        createdAt: DateTime.now(),
        type: 'purchase',
      ),
    );
    await BilletterieLocalNotifications.showTicketPurchased(
      ticketCode: ticketCode,
      orderRef: orderRef,
      routeLabel: routeLabel,
    );
  }
}
