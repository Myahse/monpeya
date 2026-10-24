/// A tenant under management, with the lease terms the rent schedule is built from.
class CollectionTenant {
  const CollectionTenant({
    required this.id,
    required this.name,
    required this.propertyId,
    this.phone,
    this.propertyName,
    this.propertyAddress,
    this.rent,
    this.frequency,
    this.leaseStart,
    this.leaseEnd,
    this.scheduledCount = 0,
  });

  final String id;
  final String name;
  final String propertyId;
  final String? phone;
  final String? propertyName;
  final String? propertyAddress;
  final double? rent;
  final String? frequency;
  final DateTime? leaseStart;
  final DateTime? leaseEnd;
  final int scheduledCount;

  bool get hasSchedule => scheduledCount > 0;

  /// The backend needs rent and both lease dates to build a schedule.
  bool get canSchedule => rent != null && leaseStart != null && leaseEnd != null;

  factory CollectionTenant.fromBackend(Map<String, dynamic> item) {
    final name = (item['nom'] as String? ?? '').trim();
    return CollectionTenant(
      id: (item['locatairesId'] ?? '').toString(),
      name: name.isEmpty ? 'Locataire' : name,
      propertyId: (item['biensId'] ?? '').toString(),
      phone: item['telephone'] as String?,
      propertyName: item['bienNom'] as String?,
      propertyAddress: item['bienAdresse'] as String?,
      rent: double.tryParse('${item['montantLoyer']}'),
      frequency: item['frequencePaiement'] as String?,
      leaseStart: DateTime.tryParse('${item['dateDebutBail']}'),
      leaseEnd: DateTime.tryParse('${item['dateFinBail']}'),
      scheduledCount: int.tryParse('${item['echeancesGenerees']}') ?? 0,
    );
  }
}
