class RentalContract {
  const RentalContract({
    required this.id,
    required this.propertyId,
    required this.tenantId,
  });

  final String id;
  final String propertyId;
  final String tenantId;
}
