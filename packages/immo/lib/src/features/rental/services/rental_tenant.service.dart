import 'package:immo/src/shared/models/immo_api.response.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/shared/services/immo_upload.service.dart';
import 'package:immo/src/features/rental/config/rental_api.endpoints.dart';
import 'package:immo/src/features/rental/models/create_tenant.draft.dart';
import 'package:immo/src/features/rental/models/rental.tenant.dart';

/// Tenants API — port from rental-app `apiService.getTenants`.
class RentalTenantService {
  RentalTenantService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient(),
        _upload = ImmoUploadService(client: client ?? ImmoApiClient());

  final ImmoApiClient _client;
  final ImmoUploadService _upload;

  Future<List<RentalTenant>> fetchTenants({String? userId}) async {
    final response = await _client.postJson(
      RentalApiEndpoints.listTenants,
      body: {
        'data': userId != null ? {'utilisateursId': userId} : null,
      },
    );

    if (!response.success || response.data == null) return const [];

    final envelope = _asEnvelope(response.data!);
    if (envelope.hasError) return const [];

    return envelope.items
        .map(RentalTenant.fromBackend)
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  Future<RentalTenant?> fetchTenantById(String id) async {
    final response = await _client.postJson(
      RentalApiEndpoints.listTenants,
      body: {
        'data': {'locatairesId': id},
      },
    );

    if (!response.success || response.data == null) return null;
    final envelope = _asEnvelope(response.data!);
    if (envelope.hasError || envelope.items.isEmpty) return null;
    return RentalTenant.fromBackend(envelope.items.first);
  }

  Future<String> createTenant(
    CreateTenantDraft draft, {
    required String utilisateursId,
  }) async {
    String? photoUrl;
    if (draft.photoPath != null && draft.photoPath!.isNotEmpty) {
      photoUrl = await _upload.uploadImagePath(draft.photoPath!);
    }

    final response = await _client.postJson(
      RentalApiEndpoints.createTenant,
      body: {
        'data': draft.toCreatePayload(
          utilisateursId: utilisateursId,
          photoUrl: photoUrl,
        ),
      },
    );

    if (!response.success) {
      throw Exception(response.error ?? 'Création du locataire impossible');
    }

    final data = response.data;
    if (data != null && data['hasError'] == true) {
      final msg = (data['status'] as Map?)?['message'] as String?;
      throw Exception(msg ?? 'Erreur backend');
    }

    final item = data?['item'] ?? data;
    if (item is Map) {
      final id = (item['locatairesId'] ?? item['id'])?.toString();
      if (id != null && id.isNotEmpty) return id;
    }

    return '';
  }

  ImmoBackendEnvelope _asEnvelope(Map<String, dynamic> data) {
    if (data.containsKey('hasError') || data.containsKey('items')) {
      return ImmoBackendEnvelope.fromJson(data);
    }
    if (data['data'] is Map) {
      return ImmoBackendEnvelope.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }
    return const ImmoBackendEnvelope();
  }
}
