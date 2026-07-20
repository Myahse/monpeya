import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// System tray / status-bar notifications for Billetterie.
class BilletterieLocalNotifications {
  BilletterieLocalNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;
  static int _idSeq = 1000;

  static const _androidChannel = AndroidNotificationChannel(
    'billetterie_tickets',
    'Billetterie',
    description: 'Achats et alertes billets',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> ensureInitialized() async {
    if (_ready) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  static Future<void> showTicketPurchased({
    required String ticketCode,
    String? orderRef,
    String? routeLabel,
  }) async {
    try {
      await ensureInitialized();

      final order = orderRef?.trim();
      final route = routeLabel?.trim();
      final body = [
        if (route != null && route.isNotEmpty) route,
        if (order != null && order.isNotEmpty) 'Ref. $order',
        'Code $ticketCode',
      ].join(' · ');

      await _plugin.show(
        _idSeq++,
        'Billet achete',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Billetterie] local notification failed: $e\n$st');
      }
    }
  }
}
