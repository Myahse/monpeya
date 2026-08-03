/// Lease / document row for Mes documents.
class RentalContract {
  const RentalContract({
    required this.id,
    required this.title,
    required this.status,
    this.propertyId,
    this.propertyName,
    this.propertyAddress,
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.rentAmount,
    this.startDate,
    this.endDate,
    this.documentType = 'Contrat de location',
  });

  final String id;
  final String title;
  final String status;
  final String? propertyId;
  final String? propertyName;
  final String? propertyAddress;
  final String? tenantId;
  final String? tenantName;
  final String? tenantPhone;
  final double? rentAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String documentType;

  bool get isActive {
    final s = status.toLowerCase();
    return s == 'actif' || s == 'active' || s == 'en_cours';
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'active':
      case 'en_cours':
        return 'Actif';
      case 'en_attente':
      case 'pending':
        return 'En attente';
      case 'inactif':
      case 'inactive':
      case 'termine':
      case 'terminé':
      case 'expire':
      case 'expiré':
        return 'Terminé';
      default:
        return status.isEmpty ? '—' : status;
    }
  }
}
