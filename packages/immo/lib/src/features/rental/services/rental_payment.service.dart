import 'package:immo/src/shared/models/immo_api.response.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/features/rental/config/rental_api.endpoints.dart';
import 'package:immo/src/features/rental/services/rental.payment.dart';

class RentalPaymentService {
  RentalPaymentService({ImmoApiClient? client}) : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  Future<List<RentalPayment>> fetchPayments() async {
    final response = await _client.postJson(
      RentalApiEndpoints.listPayments,
      body: const {'data': null},
    );

    if (!response.success || response.data == null) return const [];

    final envelope = _asEnvelope(response.data!);
    if (envelope.hasError) return const [];

    return envelope.items.map(RentalPayment.fromBackend).toList();
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
