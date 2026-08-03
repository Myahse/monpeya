import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:immo/src/shared/config/immo_api.config.dart';

/// Realtime event pushed by the Immo backend over `/ws/realtime`.
class ImmoRealtimeEvent {
  const ImmoRealtimeEvent({
    required this.type,
    this.biensId,
    this.userId,
    this.item,
    this.raw = const {},
  });

  /// e.g. `bien.created`, `bien.updated`, `bien.deleted`,
  /// `favoris.added`, `favoris.removed`, `realtime.connected`.
  final String type;
  final String? biensId;
  final String? userId;
  final Map<String, dynamic>? item;
  final Map<String, dynamic> raw;

  bool get touchesBiens =>
      type.startsWith('bien.') ||
      type.startsWith('favoris.');

  bool get touchesFavoris => type.startsWith('favoris.');

  factory ImmoRealtimeEvent.fromJson(Map<String, dynamic> json) {
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

    Map<String, dynamic>? item;
    final rawItem = data['item'] ?? json['item'];
    if (rawItem is Map) {
      item = Map<String, dynamic>.from(rawItem);
    }

    return ImmoRealtimeEvent(
      type: type,
      biensId: (data['biensId'] ?? json['biensId'] ?? item?['biensId'])
          ?.toString(),
      userId: (data['userId'] ?? json['userId'])?.toString(),
      item: item,
      raw: Map<String, dynamic>.from(data),
    );
  }
}

/// Connects to Immo `/ws/realtime` and streams [ImmoRealtimeEvent]s.
///
/// Retries quietly when the socket is unavailable — no UI errors.
class ImmoRealtimeClient {
  ImmoRealtimeClient({
    String? url,
    this.reconnectDelay = const Duration(seconds: 4),
    this.maxReconnectDelay = const Duration(seconds: 30),
  }) : url = url ?? ImmoApiConfig.wsUrl;

  final String url;
  final Duration reconnectDelay;
  final Duration maxReconnectDelay;

  final _controller = StreamController<ImmoRealtimeEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Duration _nextDelay = const Duration(seconds: 4);
  bool _disposed = false;
  bool _connecting = false;

  Stream<ImmoRealtimeEvent> get events => _controller.stream;

  bool get isConnected => _channel != null;

  void start() {
    if (_disposed) return;
    _connect();
  }

  void stop() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
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
        debugPrint('[ImmoRealtime] connecting $uri');
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
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        try {
          _channel?.sink.add('{"type":"ping"}');
        } catch (_) {}
      });
      if (kDebugMode) {
        debugPrint('[ImmoRealtime] connected');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImmoRealtime] connect failed: $e');
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
      final event = ImmoRealtimeEvent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (event.type.isEmpty) return;
      if (!_controller.isClosed) _controller.add(event);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImmoRealtime] bad message: $e');
      }
    }
  }

  void _scheduleReconnect() {
    _sub?.cancel();
    _sub = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel = null;
    if (_disposed || _reconnectTimer != null) return;
    final delay = _nextDelay;
    _nextDelay = Duration(
      milliseconds: (_nextDelay.inMilliseconds * 1.6)
          .round()
          .clamp(
            reconnectDelay.inMilliseconds,
            maxReconnectDelay.inMilliseconds,
          ),
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _connect();
    });
  }
}
