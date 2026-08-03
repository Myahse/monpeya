import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/shared/services/billetterie_location.service.dart';

Future<BilletterieLocationResult> ensureBilletterieLocation(
  BuildContext context, {
  bool forceAsk = false,
}) async {
  final granted = await BilletterieLocationService.hasGrantedPermission();
  if (granted) {
    return BilletterieLocationService.requestAndGetPosition(forceRefresh: true);
  }

  if (!context.mounted) {
    return BilletterieLocationResult.fail(
      BilletterieLocationStatus.error,
      'Impossible d’obtenir votre position.',
    );
  }

  final accepted = await showBilletterieLocationAskModal(context);
  if (!accepted) {
    return BilletterieLocationResult.fail(
      BilletterieLocationStatus.denied,
      'Autorisez l’accès à votre position pour vous situer sur la carte.',
    );
  }

  if (!context.mounted) {
    return BilletterieLocationResult.fail(
      BilletterieLocationStatus.error,
      'Impossible d’obtenir votre position.',
    );
  }

  final permission = await BilletterieLocationService.requestOsPermission();

  if (permission == LocationPermission.deniedForever) {
    if (context.mounted) {
      await showBilletterieLocationModal(
        context,
        result: BilletterieLocationResult.fail(
          BilletterieLocationStatus.deniedForever,
          'La localisation est bloquée pour Mon Peya. Ouvrez les réglages et activez-la.',
        ),
      );
    }
    return BilletterieLocationResult.fail(
      BilletterieLocationStatus.deniedForever,
      'La localisation est bloquée pour Mon Peya. Ouvrez les réglages et activez-la.',
    );
  }

  if (permission == LocationPermission.denied) {
    if (context.mounted) {
      await showBilletterieLocationModal(
        context,
        result: BilletterieLocationResult.fail(
          BilletterieLocationStatus.denied,
          'Autorisez l’accès à votre position pour vous situer sur la carte.',
        ),
        onRetry: () => ensureBilletterieLocation(context, forceAsk: true),
      );
    }
    return BilletterieLocationResult.fail(
      BilletterieLocationStatus.denied,
      'Autorisez l’accès à votre position pour vous situer sur la carte.',
    );
  }

  final result = await BilletterieLocationService.requestAndGetPosition(
    forceRefresh: true,
  );

  if (!result.hasLocation && context.mounted) {
    await showBilletterieLocationModal(
      context,
      result: result,
      onRetry: () => ensureBilletterieLocation(context, forceAsk: true),
    );
  }

  return result;
}

Future<bool> showBilletterieLocationAskModal(BuildContext context) async {
  final brand = BilletterieBrand.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.my_location_rounded, color: brand.primaryDark, size: 36),
        title: Text(
          'Utiliser votre position ?',
          style: TextStyle(
            color: brand.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Mon Peya a besoin de votre position pour vous situer sur la carte et afficher les événements et trajets à proximité.',
          style: TextStyle(color: brand.muted, fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Pas maintenant', style: TextStyle(color: brand.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: brand.primaryDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Autoriser'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<void> showBilletterieLocationModal(
  BuildContext context, {
  required BilletterieLocationResult result,
  VoidCallback? onRetry,
}) {
  final status = result.status;
  final needsSettings = status == BilletterieLocationStatus.deniedForever ||
      status == BilletterieLocationStatus.serviceDisabled;
  final brand = BilletterieBrand.of(context);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          status == BilletterieLocationStatus.serviceDisabled
              ? Icons.location_disabled_rounded
              : Icons.location_on_outlined,
          color: brand.primaryDark,
          size: 36,
        ),
        title: Text(
          'Position requise',
          style: TextStyle(
            color: brand.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          result.message ??
              'Autorisez la localisation pour utiliser votre position actuelle.',
          style: TextStyle(color: brand.muted, fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Fermer', style: TextStyle(color: brand.muted)),
          ),
          if (needsSettings)
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (status == BilletterieLocationStatus.serviceDisabled) {
                  await BilletterieLocationService.openLocationSettings();
                } else {
                  await BilletterieLocationService.openAppSettings();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: brand.primaryDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réglages'),
            )
          else
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRetry?.call();
              },
              style: FilledButton.styleFrom(
                backgroundColor: brand.primaryDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
        ],
      );
    },
  );
}
