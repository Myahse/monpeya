import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../models/rental_property.dart';
import '../auth/rental_session_scope.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    required this.onBack,
  });

  final String propertyId;
  final VoidCallback onBack;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  RentalProperty? _property;
  String? _error;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final property =
          await RentalSessionScope.of(context).api.properties.fetchPropertyById(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _property = property;
        if (property == null) _error = 'Bien introuvable';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: _ErrorView(message: _error!, onBack: widget.onBack, onRetry: _load),
      );
    }

    if (_property == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
          backgroundColor: ImmoBrand.rentalPrimary,
          foregroundColor: Colors.white,
        ),
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _buildContent(_property!),
    );
  }

  Widget _buildContent(RentalProperty property) {
    final images = property.imageUrls.isNotEmpty
        ? property.imageUrls
        : (property.imageUrl != null ? [property.imageUrl!] : <String>[]);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: ImmoBrand.rentalPrimary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: images.isEmpty
                ? ColoredBox(
                    color: ImmoBrand.rentalPrimary.withValues(alpha: 0.2),
                    child: const Center(
                      child: Icon(Icons.home_work_outlined, size: 64, color: Colors.white),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: ImmoBrand.rentalDark,
                            child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _imageIndex
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.locationLabel.isNotEmpty
                            ? property.locationLabel
                            : property.address,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  property.formattedPrice,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ImmoBrand.rentalPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Type', value: property.propertyType),
                _InfoRow(label: 'Surface', value: '${property.surface.toStringAsFixed(0)} m²'),
                _InfoRow(label: 'Statut', value: property.statusLabel),
                if (property.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    style: TextStyle(height: 1.5, color: Colors.grey.shade800),
                  ),
                ],
                if (property.amenities.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Équipements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in property.amenities)
                        Chip(
                          label: Text(a),
                          backgroundColor:
                              ImmoBrand.rentalPrimary.withValues(alpha: 0.08),
                        ),
                    ],
                  ),
                ],
                if (property.ownerName.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Propriétaire',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Nom', value: property.ownerName),
                  if (property.ownerPhone.isNotEmpty)
                    _InfoRow(label: 'Téléphone', value: property.ownerPhone),
                  if (property.ownerEmail.isNotEmpty)
                    _InfoRow(label: 'Email', value: property.ownerEmail),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
