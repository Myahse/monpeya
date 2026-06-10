class CollectionContract {
  const CollectionContract({
    required this.id,
    required this.propertyId,
    required this.tenantName,
  });

  final String id;
  final String propertyId;
  final String tenantName;
}
