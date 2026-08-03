import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:billetterie/src/shared/config/billetterie_api.config.dart';

/// Ticketing realtime event pushed by the backend over WebSocket.
class BilletterieRealtimeEvent {
  const BilletterieRealtimeEvent({
    required this.type,
    this.purpose,
    this.codeClient,
    this.eventCode,
    this.ticketCode,
    this.raw = const {},
  });

  /// e.g. `ticket.created`, `ticket.sold`, `ticket.consumed`,
  /// `event.published`, `event.updated`, `dashboard.changed`.
  final String type;
  final String? purpose;
  final String? codeClient;
  final String? eventCode;
  final String? ticketCode;
  final Map<String, dynamic> raw;

  bool get touchesTransport {
    final p = purpose?.toUpperCase();
    if (p == 'TRANSPORT') return true;
    if (p == 'EVENT') return false;
    return type.startsWith('ticket.') || type == 'dashboard.changed';
  }

  bool get touchesEvent {
    final p = purpose?.toUpperCase();
    if (p == 'EVENT') return true;
    if (p == 'TRANSPORT') return false;
    return type.startsWith('event.') ||
        type == 'dashboard.changed' ||
        type.startsWith('ticket.');
  }

  factory BilletterieRealtimeEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final type = (data['type'] ??
            data['event'] ??
            data['action'] ??
            json['type'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    return BilletterieRealtimeEvent(
      type: type,
      purpose: (data['purpose'] ?? json['purpose'])?.toString(),
      codeClient: (data['codeClient'] ?? json['codeClient'])?.toString(),
      eventCode: (data['eventCode'] ?? json['eventCode'])?.toString(),
      ticketCode: (data['ticketCode'] ?? json['ticketCode'])?.toString(),
      raw: data,
    );
  }
}

/// Connects to the ticketing WebSocket and streams [BilletterieRealtimeEvent]s.
///
/// Expected backend path (configurable): `ws(s)://{host}/ws`
/// Message: JSON object, optionally wrapped as `{ "data": { "type": "..." } }`.
///
/// If the socket is unavailable the client retries quietly — no UI errors.
class BilletterieRealtimeClient {
  BilletterieRealtimeClient({
    String? url,
    this.reconnectDelay = const Duration(seconds: 4),
    this.maxReconnectDelay = const Duration(seconds: 30),
  }) : url = url ?? BilletterieApiConfig.wsUrl;

  final String url;
  final Duration reconnectDelay;
  final Duration maxReconnectDelay;

  final _controller = StreamController<BilletterieRealtimeEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Duration _nextDelay = const Duration(seconds: 4);
  bool _disposed = false;
  bool _connecting = false;

  Stream<BilletterieRealtimeEvent> get events => _controller.stream;

  bool get isConnected => _channel != null;

  void start() {
    if (_disposed) return;
    _connect();
  }

  void stop() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    stop();
    _controller.close();
  }

  Future<void> _connect() async {
    if (_disposed || _connecting) return;
    _connecting = true;
    stop();
    try {
      final uri = Uri.parse(url);
      if (kDebugMode) {
        debugPrint('[BilletterieRealtime] connecting $uri');
      }
      final channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(const Duration(seconds: 8));
      if (_disposed) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _nextDelay = reconnectDelay;
      _sub = channel.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      if (kDebugMode) {
        debugPrint('[BilletterieRealtime] connected');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BilletterieRealtime] connect failed: $e');
      }
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final text = raw is String ? raw : raw?.toString();
      if (text == null || text.isEmpty) return;
      final decoded = jsonDecode(text);
      if (decoded is! Map) return;
      final event = BilletterieRealtimeEvent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (event.type.isEmpty) return;
      if (!_controller.isClosed) _controller.add(event);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BilletterieRealtime] bad message: $e');
      }
    }
  }

  void _scheduleReconnect() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (_disposed || _reconnectTimer != null) return;
    final delay = _nextDelay;
    _nextDelay = Duration(
      milliseconds: (_nextDelay.inMilliseconds * 1.6)
          .round()
          .clamp(reconnectDelay.inMilliseconds, maxReconnectDelay.inMilliseconds),
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _connect();
    });
  }
}
