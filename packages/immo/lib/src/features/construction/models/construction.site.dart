/// A chantier as returned by `/api/chantiers` (ChantiersDto).
class ConstructionSite {
  const ConstructionSite({
    required this.id,
    required this.name,
    this.status,
    this.address,
    this.city,
    this.surfaceM2,
    this.budget,
    this.estimatedCost,
    this.startDate,
    this.plannedEnd,
    this.actualEnd,
    this.rentalOpenedAt,
    this.propertyId,
  });

  final String id;
  final String name;

  /// Backend code: `planifié`, `en_cours`, `suspendu_chantier`, `terminé`…
  final String? status;
  final String? address;
  final String? city;
  final double? surfaceM2;
  final double? budget;
  final double? estimatedCost;
  final DateTime? startDate;
  final DateTime? plannedEnd;
  final DateTime? actualEnd;
  final DateTime? rentalOpenedAt;

  /// The bien it became once passed to Mr Immo Location.
  final String? propertyId;

  bool get handedOver => propertyId != null && propertyId!.isNotEmpty;

  bool get finished => handedOver || (status?.startsWith('termin') ?? false);

  bool get paused => status?.startsWith('suspendu') ?? false;

  bool get planned => status?.startsWith('planifi') ?? false;

  bool get active => !finished && !paused;

  String get statusLabel {
    if (handedOver) return 'En location';
    if (finished) return 'Terminé';
    if (paused) return 'En pause';
    if (planned) return 'Planifié';
    return 'En cours';
  }

  /// Share of the planned duration already elapsed, 0–1 (null without dates).
  double? elapsed(DateTime now) {
    final start = startDate;
    final end = plannedEnd;
    if (start == null || end == null || !end.isAfter(start)) return null;
    final total = end.difference(start).inMinutes;
    final done = now.difference(start).inMinutes;
    return (done / total).clamp(0.0, 1.0);
  }

  factory ConstructionSite.fromBackend(Map<String, dynamic> item) {
    DateTime? date(String key) => DateTime.tryParse('${item[key]}');
    double? number(String key) => double.tryParse('${item[key]}');
    final name = (item['nom'] as String? ?? '').trim();
    return ConstructionSite(
      id: (item['chantiersId'] ?? '').toString(),
      name: name.isEmpty ? 'Chantier' : name,
      status: item['statut'] as String?,
      address: item['adresse'] as String?,
      city: item['ville'] as String?,
      surfaceM2: number('surfaceM2'),
      budget: number('budgetAlloue'),
      estimatedCost: number('coutsEstimes'),
      startDate: date('dateDebut'),
      plannedEnd: date('dateFinPrevue'),
      actualEnd: date('dateFinReelle'),
      rentalOpenedAt: date('dateOuvertureLocation'),
      propertyId: item['biensId']?.toString(),
    );
  }
}
