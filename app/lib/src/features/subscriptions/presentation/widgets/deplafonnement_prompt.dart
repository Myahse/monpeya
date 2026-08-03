import 'package:flutter/material.dart';

import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_error.ui.dart';
import 'package:app/src/integration/adapters/mon_peya_backend.adapter.dart';

/// If a CLIENT account is known not to be déplafonné, ask them to request it.
/// Returns `true` when subscribe may proceed.
///
/// Only blocks when we positively know the account is not déplafonné.
/// Missing/unknown status lets subscribe continue (backend enforces).
Future<bool> ensureDeplafonneOrAsk(
  BuildContext context, {
  String role = 'CLIENT',
}) async {
  if (role.toUpperCase() != 'CLIENT') return true;

  bool? isDeplafonne;
  try {
    final me = await monPeyaMe();
    isDeplafonne = me.isDeplafonne;
  } catch (_) {
    // Ignore — fall back / allow subscribe.
  }

  // Live PeyaPay client state (same source as wallet `deplafonner`).
  if (isDeplafonne != true) {
    final fromPeya = PeyapayHostBridge.api?.clientState?.deplafonner;
    if (fromPeya == true) {
      isDeplafonne = true;
    } else if (isDeplafonne == null && fromPeya == false) {
      isDeplafonne = false;
    }
  }

  if (isDeplafonne == true) return true;
  // Unknown → do not block a déplafonné account on a missing field.
  if (isDeplafonne != false) return true;

  if (!context.mounted) return false;

  var pending = false;
  try {
    final reqs = await monPeyaMySubscriptionRequests();
    pending = reqs.any((r) => r.isDeplafonnement && r.isOpen);
  } catch (_) {}

  if (!context.mounted) return false;

  if (pending) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déplafonnement en cours'),
        content: const Text(
          'Votre demande de déplafonnement est en cours de validation. '
          'Vous pourrez vous abonner une fois qu’elle sera acceptée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  final ask = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Compte non déplafonné'),
      content: const Text(
        'Pour vous abonner, votre compte doit d’abord être déplafonné. '
        'Souhaitez-vous envoyer une demande maintenant ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Demander'),
        ),
      ],
    ),
  );

  if (ask != true || !context.mounted) return false;

  try {
    await monPeyaRequestDeplafonnement();
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demande de déplafonnement envoyée. Vous pourrez vous abonner après validation.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on MonPeyaApiException catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(monPeyaUserMessage(e)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  return false;
}
