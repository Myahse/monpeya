import 'package:immo/src/shared/models/immo_api.response.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/features/rental/config/rental_api.endpoints.dart';
import 'package:immo/src/features/rental/models/rental.contract.dart';

/// Leases: the owner's list, one lease, creating it, the owner's signature and
/// the answer to a termination request. Failures throw with the backend's message.
class RentalContractService {
  RentalContractService({ImmoApiClient? client}) : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  /// The owner's leases, newest first.
  Future<List<RentalContract>> fetchOwnerContracts({required String userId}) async {
    final envelope = _envelope(await _client.postJson(
      RentalApiEndpoints.listContracts,
      body: {
        'data': {'utilisateursId': userId},
      },
    ));
    // "No rental contracts found" comes back as an empty list, not an error
    if (envelope.hasError) throw Exception(envelope.message ?? 'Chargement impossible');
    return envelope.items.map(RentalContract.fromBackend).where((c) => c.id.isNotEmpty).toList();
  }

  Future<RentalContract?> fetchContract(String id) async {
    final envelope = _envelope(await _client.getJson(RentalApiEndpoints.contract(id)));
    if (envelope.hasError) throw Exception(envelope.message ?? 'Chargement impossible');
    final item = envelope.item ?? (envelope.items.isEmpty ? null : envelope.items.first);
    return item == null ? null : RentalContract.fromBackend(item);
  }

  /// The lease of a tenant just created, waiting for both signatures.
  Future<RentalContract> createContract({
    required String ownerId,
    required String propertyId,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required double monthlyRent,
    required double deposit,
    required String paymentMode,
    required String periodicity,
  }) async {
    final envelope = _envelope(await _client.postJson(
      RentalApiEndpoints.createContract,
      body: {
        'data': {
          'utilisateursId': ownerId,
          'biensId': propertyId,
          'locatairesId': tenantId,
          'dateDebut': _day(startDate),
          'dateFin': _day(endDate),
          'loyerMensuel': monthlyRent,
          'caution': deposit,
          'fraisAgence': 0,
          'modePaiement': paymentMode,
          'periodicite': periodicity,
        },
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Contrat non créé');
    }
    return RentalContract.fromBackend(envelope.item!);
  }

  /// The owner signs [contractId] with [signature] (a `data:image/png;base64,…` URI)
  /// and rates the tenant from 1 to 5.
  Future<RentalContract> signAsOwner({
    required String contractId,
    required String signature,
    required int tenantRating,
    String? comment,
  }) async {
    final envelope = _envelope(await _client.postJson(
      RentalApiEndpoints.signContractAsOwner,
      body: {
        'contratsLocationId': contractId,
        'signatureData': signature,
        'tenantRating': tenantRating,
        'ratingComment': ?comment,
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Signature non enregistrée');
    }
    return RentalContract.fromBackend(envelope.item!);
  }

  /// The owner accepts or refuses the tenant's early termination request.
  Future<void> decideTermination({
    required String contractId,
    required bool approve,
    String? notes,
  }) async {
    final envelope = _envelope(await _client.postJson(
      RentalApiEndpoints.decideTermination(contractId),
      body: {'approved': approve, 'notes': ?notes},
    ));
    if (envelope.hasError) throw Exception(envelope.message ?? 'Réponse non enregistrée');
  }

  /// A link to the lease's PDF that opens without a sign-in for a few minutes, so the
  /// phone's browser can show it. Asked for as the signed-in owner.
  Future<Uri> pdfLink(RentalContract contract) async {
    final envelope = _envelope(await _client.postJson(RentalApiEndpoints.contractPdfLink(contract.id)));
    final url = envelope.item?['urlPdf'] as String?;
    if (envelope.hasError || url == null || url.isEmpty) {
      throw Exception(envelope.message ?? 'PDF indisponible');
    }
    return _client.resolve(url);
  }

  static String _day(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  ImmoBackendEnvelope _envelope(ImmoApiResponse<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      return ImmoBackendEnvelope(hasError: true, message: response.error);
    }
    final envelope = ImmoBackendEnvelope.fromJson(data);
    if (!response.success && !envelope.hasError) {
      return ImmoBackendEnvelope(hasError: true, message: envelope.message ?? response.error);
    }
    return envelope;
  }
}
