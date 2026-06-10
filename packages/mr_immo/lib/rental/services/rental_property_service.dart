import '../../shared/models/immo_api_response.dart';
import '../../shared/services/immo_api_client.dart';
import '../../shared/services/immo_country_service.dart';
import '../../shared/services/immo_upload_service.dart';
import '../config/rental_api_endpoints.dart';
import '../models/create_listing_draft.dart';
import '../models/rental_property.dart';

/// Properties API — port from rental-app `propertyService.ts`.
class RentalPropertyService {
  RentalPropertyService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient(),
        _upload = ImmoUploadService(client: client ?? ImmoApiClient()),
        _countries = ImmoCountryService(client: client ?? ImmoApiClient());

  final ImmoApiClient _client;
  final ImmoUploadService _upload;
  final ImmoCountryService _countries;

  Future<List<RentalProperty>> fetchProperties({String? search}) async {
    final response = await _client.postJson(
      RentalApiEndpoints.listProperties,
      body: {'data': search != null && search.isNotEmpty ? {'nom': search} : null},
    );

    final items = _extractItems(response);
    return items
        .map((e) => RentalProperty.fromBackend(e, apiBaseUrl: _client.baseUrl))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  Future<RentalProperty?> fetchPropertyById(String id) async {
    final response = await _client.getJson('${RentalApiEndpoints.publicProperty}/$id');
    if (!response.success || response.data == null) return null;

    final envelope = _asEnvelope(response.data!);
    if (envelope.hasError) return null;

    Map<String, dynamic>? raw;
    if (envelope.items.isNotEmpty) {
      raw = envelope.items.first;
    } else if (envelope.item != null) {
      raw = envelope.item;
    } else {
      raw = response.data;
    }

    if (raw == null) return null;
    return RentalProperty.fromBackend(raw, apiBaseUrl: _client.baseUrl);
  }

  Future<void> createProperty(
    CreateListingDraft draft, {
    String? utilisateursId,
  }) async {
    final photoUrls = await _upload.uploadImagePaths(draft.photoPaths);
    final codePaysId = await _countries.resolveCountryId(
      latitude: draft.latitude,
      longitude: draft.longitude,
    );

    final response = await _client.postJson(
      RentalApiEndpoints.createProperty,
      body: {
        'data': draft.toCreatePayload(
          utilisateursId: utilisateursId,
          photoUrls: photoUrls,
          codePaysId: codePaysId,
        ),
      },
    );

    if (!response.success) {
      throw Exception(response.error ?? 'Création du bien impossible');
    }

    final data = response.data;
    if (data != null && data['hasError'] == true) {
      final msg = (data['status'] as Map?)?['message'] as String?;
      throw Exception(msg ?? 'Erreur backend');
    }
  }

  List<Map<String, dynamic>> _extractItems(ImmoApiResponse<Map<String, dynamic>> response) {
    if (!response.success || response.data == null) return const [];
    return _asEnvelope(response.data!).items;
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
    return ImmoBackendEnvelope(items: [data]);
  }
}
