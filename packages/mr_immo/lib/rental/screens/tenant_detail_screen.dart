import 'package:flutter/material.dart';

import '../../immo_brand.dart';
import '../auth/rental_session_scope.dart';
import '../models/rental_tenant.dart';

String _resolvePhotoUrl(String photo, String apiBase) {
  if (photo.startsWith('http')) {
    return _fixLocalhost(photo, apiBase);
  }
  if (photo.startsWith('/')) {
    return _fixLocalhost('$apiBase$photo', apiBase);
  }
  return photo;
}

String _fixLocalhost(String url, String apiBase) {
  if (!url.contains('localhost')) return url;
  final host = Uri.tryParse(apiBase)?.host;
  if (host == null || host == 'localhost') return url;
  return url
      .replaceAll('localhost:8081', '$host:8081')
      .replaceAll('localhost:8080', '$host:8081');
}

class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({
    super.key,
    required this.tenantId,
    required this.onBack,
  });

  final String tenantId;
  final VoidCallback onBack;

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  RentalTenant? _tenant;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final tenant = await RentalSessionScope.of(context)
          .api
          .tenants
          .fetchTenantById(widget.tenantId);
      if (!mounted) return;
      setState(() {
        _tenant = tenant;
        if (tenant == null) _error = 'Locataire introuvable';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text('Locataire'),
        backgroundColor: ImmoBrand.rentalPrimary,
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _tenant == null
              ? const SizedBox.shrink()
              : _buildContent(_tenant!),
    );
  }

  Widget _buildContent(RentalTenant tenant) {
    final photo = tenant.photoUrl;
    final apiBase = RentalSessionScope.of(context).api.client.baseUrl;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: ImmoBrand.rentalPrimary.withValues(alpha: 0.15),
            backgroundImage: photo != null && photo.isNotEmpty
                ? NetworkImage(_resolvePhotoUrl(photo, apiBase))
                : null,
            child: photo == null || photo.isEmpty
                ? Text(
                    tenant.initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: ImmoBrand.rentalPrimary,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tenant.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          tenant.status.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, letterSpacing: 1),
        ),
        const SizedBox(height: 24),
        _infoTile(Icons.email_outlined, 'Email', tenant.email),
        _infoTile(Icons.phone_outlined, 'Téléphone', tenant.phone),
        if (tenant.profession != null && tenant.profession!.isNotEmpty)
          _infoTile(Icons.work_outline, 'Profession', tenant.profession!),
        if (tenant.monthlyIncome != null)
          _infoTile(
            Icons.payments_outlined,
            'Revenu mensuel',
            '${tenant.monthlyIncome!.toStringAsFixed(0)} FCFA',
          ),
        if (tenant.propertyName != null && tenant.propertyName!.isNotEmpty)
          _infoTile(Icons.home_work_outlined, 'Bien', tenant.propertyName!),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: ImmoBrand.rentalPrimary),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
