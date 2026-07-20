class PeyapayScannedQrData {
  const PeyapayScannedQrData({
    required this.clientCodeKey,
    this.displayName,
    this.userTypeKey,
    this.isExpired = false,
  });

  final String clientCodeKey;
  final String? displayName;
  final String? userTypeKey;
  final bool isExpired;

  bool get isMerchant => userTypeKey == 'MPP';

  String get recipientLabel => displayName?.trim().isNotEmpty == true ? displayName!.trim() : 'Destinataire Peya Pay';
}
