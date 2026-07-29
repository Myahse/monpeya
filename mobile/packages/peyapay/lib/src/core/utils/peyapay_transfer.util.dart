import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/data/models/peyapay_api.exception.dart';
import 'package:peyapay/src/data/models/peyapay_client_transfer.model.dart';
import 'package:peyapay/src/data/services/peyapay_crypto.service.dart'
    show normalizePeyapayPhone;

Future<PeyapayClientTransferResult> peyapayExecuteClientTransfer({
  required String recipientPhone,
  required int amountReceived,
  int fee = 0,
}) async {
  final api = PeyapayHostBridge.api;
  final auth = PeyapayHostBridge.requireAuth;
  if (api == null) {
    throw PeyapayApiException(message: 'API PeyaPay non initialisée');
  }

  final senderPhone = await auth.getPhone();
  if (senderPhone == null || senderPhone.trim().isEmpty) {
    throw PeyapayApiException(message: 'Numéro expéditeur indisponible');
  }

  final recipientDigits = normalizePeyapayPhone(recipientPhone);
  if (recipientDigits.length != 10) {
    throw PeyapayApiException(message: 'Numéro destinataire invalide (10 chiffres attendus)');
  }

  await api.hydrateBearerFrom(auth.authToken, preferAppToken: false);

  final result = await api.transferToClient(
    senderPhone: senderPhone,
    recipientPhone: recipientDigits,
    amountReceived: amountReceived,
    fee: fee,
    ensureToken: false,
  );

  PeyapayHostBridge.notifySessionChanged();
  return result;
}

Future<bool> peyapayIsWalletPhone(String phone) async {
  final api = PeyapayHostBridge.api;
  if (api == null) return false;

  final digits = normalizePeyapayPhone(phone);
  if (digits.length != 10) return false;

  try {
    final search = await api.searchGsm(phone: digits, ensureToken: false);
    return search.isRecognized;
  } catch (_) {
    return false;
  }
}
