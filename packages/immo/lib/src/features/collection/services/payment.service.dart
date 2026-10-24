import 'package:immo/src/features/collection/config/collection_api.endpoints.dart';
import 'package:immo/src/features/collection/models/payment.model.dart';
import 'package:immo/src/shared/models/immo_api.response.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

class CollectionPaymentService {
  CollectionPaymentService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  /// Rent rows for the properties [userId] manages, oldest due date first.
  Future<List<CollectionPayment>> fetchPayments({
    required String userId,
    String? propertyId,
  }) async {
    final response = await _client.getJson(CollectionApiEndpoints.payments(userId));
    final envelope = _envelope(response);
    if (envelope.hasError) {
      throw Exception(envelope.message ?? response.error ?? 'Chargement impossible');
    }
    final payments = envelope.items
        .map(CollectionPayment.fromBackend)
        .where((p) => p.id.isNotEmpty);
    return (propertyId == null
            ? payments
            : payments.where((p) => p.propertyId == propertyId))
        .toList();
  }

  Future<void> markPaid(
    String paymentId, {
    required String method,
    String? reference,
  }) async {
    final query = Uri(queryParameters: {
      'methodePaiement': method,
      if (reference != null && reference.trim().isNotEmpty)
        'reference': reference.trim(),
    }).query;
    final response = await _client.putJson(
      '${CollectionApiEndpoints.markPaid(paymentId)}?$query',
    );
    final envelope = _envelope(response);
    if (envelope.hasError) {
      throw Exception(envelope.message ?? response.error ?? 'Encaissement refusé');
    }
  }

  /// Builds the tenant's rent schedule from their lease (amount, dates, frequency).
  Future<int> generateSchedule({
    required String tenantId,
    required String userId,
  }) async {
    final query = Uri(queryParameters: {'userId': userId}).query;
    final response = await _client.postJson(
      '${CollectionApiEndpoints.generateSchedule(tenantId)}?$query',
    );
    final envelope = _envelope(response);
    if (envelope.hasError) {
      throw Exception(envelope.message ?? response.error ?? 'Échéancier non créé');
    }
    return envelope.items.length;
  }

  ImmoBackendEnvelope _envelope(ImmoApiResponse<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      return ImmoBackendEnvelope(
        hasError: !response.success,
        message: response.error,
      );
    }
    final envelope = ImmoBackendEnvelope.fromJson(data);
    if (!response.success && !envelope.hasError) {
      return ImmoBackendEnvelope(hasError: true, message: envelope.message ?? response.error);
    }
    return envelope;
  }
}
