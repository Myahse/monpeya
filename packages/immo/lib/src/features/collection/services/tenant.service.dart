import 'package:immo/src/features/collection/config/collection_api.endpoints.dart';
import 'package:immo/src/features/collection/models/tenant.model.dart';
import 'package:immo/src/shared/models/immo_api.response.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

class CollectionTenantService {
  CollectionTenantService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  Future<List<CollectionTenant>> fetchTenants({required String userId}) async {
    final response = await _client.getJson(CollectionApiEndpoints.tenants(userId));
    final data = response.data;
    final envelope = data == null
        ? ImmoBackendEnvelope(hasError: !response.success, message: response.error)
        : ImmoBackendEnvelope.fromJson(data);
    if (envelope.hasError || !response.success) {
      throw Exception(envelope.message ?? response.error ?? 'Chargement impossible');
    }
    return envelope.items
        .map(CollectionTenant.fromBackend)
        .where((t) => t.id.isNotEmpty)
        .toList();
  }
}
