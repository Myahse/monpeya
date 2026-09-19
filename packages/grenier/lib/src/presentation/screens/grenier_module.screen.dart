import 'dart:async';

import 'package:flutter/material.dart';

import 'package:grenier/src/core/constants/grenier.brand.dart';
import 'package:grenier/src/core/host/grenier_host.bridge.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';
import 'package:grenier/src/shared/services/grenier_api.service.dart';
import 'package:grenier/src/shared/services/grenier_realtime.client.dart';

class GrenierModuleScreen extends StatefulWidget {
  const GrenierModuleScreen({super.key});

  @override
  State<GrenierModuleScreen> createState() => _GrenierModuleScreenState();
}

class _GrenierModuleScreenState extends State<GrenierModuleScreen> {
  final _api = GrenierApiService();
  final _realtime = GrenierRealtimeClient();
  StreamSubscription<List<GrenierProduit>>? _sub;
  List<GrenierProduit> _items = const [];
  bool _loading = true;
  String? _error;
  String? _flashId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listProduits();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      _realtime.connect(initial: items);
      _sub = _realtime.stream.listen((next) {
        if (!mounted) return;
        final changed = _detectChangedId(_items, next);
        setState(() {
          _items = next;
          _flashId = changed;
        });
        if (changed != null) {
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (mounted && _flashId == changed) {
              setState(() => _flashId = null);
            }
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _detectChangedId(
    List<GrenierProduit> prev,
    List<GrenierProduit> next,
  ) {
    final prevMap = {for (final i in prev) i.id: i.price};
    for (final i in next) {
      if (prevMap[i.id] != i.price) return i.id.toString();
    }
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: GrenierBrand.primary,
        foregroundColor: Colors.white,
        title: const Text(GrenierBrand.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GrenierHostBridge.exitModule(context),
        ),
        actions: [
          IconButton(
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _bootstrap,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      color: GrenierBrand.primaryDark,
                      child: const Text(
                        'Prix des produits en temps réel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final flash = _flashId == item.id.toString();
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: flash
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: flash
                                    ? GrenierBrand.primary
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      GrenierBrand.primary.withValues(alpha: 0.12),
                                  child: const Icon(
                                    Icons.shopping_basket_outlined,
                                    color: GrenierBrand.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '${item.unit} · ${item.market ?? 'Marché'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.priceLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: GrenierBrand.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
