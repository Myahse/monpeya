abstract final class CollectionApiEndpoints {
  static String payments(String userId) => '/api/paiements/collection/$userId';
  static String tenants(String userId) =>
      '/api/paiements/collection/$userId/tenants';
  static String markPaid(String paymentId) =>
      '/api/paiements/$paymentId/mark-paid';
  static String generateSchedule(String tenantId) =>
      '/api/paiements/generate/$tenantId';
}

/// Methods offered when marking a rent as collected (stored as-is in `methode_paiement`).
abstract final class CollectionPaymentMethods {
  static const all = ['Espèces', 'Mobile money', 'Peya Pay', 'Virement'];
}
