import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/features/rental/services/rental_message.service.dart';
import 'package:immo/src/features/rental/services/rental_payment.service.dart';
import 'package:immo/src/features/rental/services/rental_property.service.dart';
import 'package:immo/src/features/rental/services/rental_tenant.service.dart';

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
