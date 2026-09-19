import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:grenier/src/shared/config/grenier_api.config.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';

class GrenierRealtimeClient {
  WebSocketChannel? _channel;
  final _controller = StreamController<List<GrenierProduit>>.broadcast();
  List<GrenierProduit> _items = const [];

  Stream<List<GrenierProduit>> get stream => _controller.stream;
  List<GrenierProduit> get current => _items;

  void connect({List<GrenierProduit> initial = const []}) {
    disconnect();
    _items = List.of(initial);
    final channel = WebSocketChannel.connect(Uri.parse(GrenierApiConfig.wsUrl));
    _channel = channel;
    channel.stream.listen(
      _onMessage,
      onError: (_) {},
      onDone: () => _channel = null,
      cancelOnError: true,
    );
    channel.sink.add(jsonEncode({'type': 'subscribe'}));
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final type = decoded['type']?.toString();
    if (type == 'produits.snapshot' || type == 'ingredients.snapshot') {
      final items = decoded['items'];
      if (items is List) {
        _items = items
            .whereType<Map>()
            .map((e) => GrenierProduit.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _controller.add(_items);
      }
      return;
    }
    if (type == 'produit.price' ||
        type == 'produit.upserted' ||
        type == 'ingredient.price' ||
        type == 'ingredient.upserted') {
      final itemRaw = decoded['item'];
      if (itemRaw is! Map) return;
      final item = GrenierProduit.fromJson(Map<String, dynamic>.from(itemRaw));
      final next = [..._items];
      final idx = next.indexWhere((e) => e.id == item.id);
      if (idx >= 0) {
        next[idx] = item;
      } else {
        next.add(item);
        next.sort((a, b) => a.name.compareTo(b.name));
      }
      _items = next;
      _controller.add(_items);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
