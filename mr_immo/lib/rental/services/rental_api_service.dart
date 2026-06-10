import '../../shared/services/immo_api_client.dart';
import 'rental_message_service.dart';
import 'rental_payment_service.dart';
import 'rental_property_service.dart';
import 'rental_tenant_service.dart';

/// Facade for Mr Immo Location API services.
class RentalApiService {
  RentalApiService._(this.client)
      : properties = RentalPropertyService(client: client),
        tenants = RentalTenantService(client: client),
        payments = RentalPaymentService(client: client),
        messages = RentalMessageService(client: client);

  factory RentalApiService({ImmoApiClient? client}) =>
      RentalApiService._(client ?? ImmoApiClient());

  final ImmoApiClient client;
  final RentalPropertyService properties;
  final RentalTenantService tenants;
  final RentalPaymentService payments;
  final RentalMessageService messages;

  static final instance = RentalApiService();
}
