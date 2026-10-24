import 'package:immo/src/features/collection/models/property.model.dart';
import 'package:immo/src/features/collection/models/tenant.model.dart';
import 'package:immo/src/features/collection/services/tenant.service.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

class CollectionPropertyService {
  CollectionPropertyService({ImmoApiClient? client})
      : _tenants = CollectionTenantService(client: client);

  final CollectionTenantService _tenants;

  /// Properties with at least one tenant — what there is rent to collect on.
  Future<List<CollectionProperty>> fetchProperties({required String userId}) async =>
      propertiesOf(await _tenants.fetchTenants(userId: userId));

  static List<CollectionProperty> propertiesOf(List<CollectionTenant> tenants) {
    final byId = <String, List<CollectionTenant>>{};
    for (final t in tenants) {
      if (t.propertyId.isEmpty) continue;
      byId.putIfAbsent(t.propertyId, () => []).add(t);
    }
    return [
      for (final entry in byId.entries)
        CollectionProperty(
          id: entry.key,
          name: entry.value.first.propertyName ?? 'Bien',
          address: entry.value.first.propertyAddress,
          unitCount: entry.value.length,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }
}
