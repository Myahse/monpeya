import 'package:peyapay/peyapay.dart';

import 'package:billetterie/src/shared/config/billetterie_env.registry.dart';
import 'package:billetterie/src/shared/models/billetterie.ticket.dart';

/// Builds SecureQR payloads for ticketing (server validates via `/v1/tickets/verify`).
class BilletterieQrService {
  BilletterieQrService({String? secretKey})
      : _qr = PeyapayQrService(
          secretKey: secretKey ?? BilletterieEnvRegistry.qrEncryptKey,
        );

  final PeyapayQrService _qr;

  bool get hasSecretKey => _qr.hasSecretKey;

  Future<String> buildTicketQrContent(BilletterieTicket ticket) async {
    final result = await _qr.generateTicketQr(
      ticketCode: ticket.id,
      eventCode: ticket.eventCode,
      purpose: ticket.purpose ?? 'EVENT',
      title: ticket.typeName,
    );
    return result.qrContent;
  }
}
