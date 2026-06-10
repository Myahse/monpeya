class CollectionProperty {
  const CollectionProperty({
    required this.id,
    required this.name,
    this.address,
    this.unitCount,
  });

  final String id;
  final String name;
  final String? address;
  final int? unitCount;
}
