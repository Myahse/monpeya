class ConstructionSite {
  const ConstructionSite({
    required this.id,
    required this.name,
    this.status,
  });

  final String id;
  final String name;
  final String? status;
}
