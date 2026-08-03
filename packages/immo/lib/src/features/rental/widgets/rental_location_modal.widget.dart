import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:immo/src/features/rental/services/rental_location.service.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';

/// Asks the user for location, then triggers the OS permission dialog and GPS fix.
///
/// Returns the location result (granted + coordinates, or a failure status).
Future<RentalLocationResult> ensureRentalLocation(
  BuildContext context, {
  bool forceAsk = false,
}) async {
  final granted = await RentalLocationService.hasGrantedPermission();
  if (granted) {
    return RentalLocationService.requestAndGetPosition(
      forceRefresh: forceAsk,
    );
  }

  if (!context.mounted) {
    return RentalLocationResult.fail(
      RentalLocationStatus.error,
      'Impossible d’obtenir votre position.',
    );
  }

  // Ask in-app first, then the OS permission dialog.
  final accepted = await showRentalLocationAskModal(context);
  if (!accepted) {
    return RentalLocationResult.fail(
      RentalLocationStatus.denied,
      'Autorisez l’accès à votre position pour afficher les biens autour de vous.',
    );
  }

  if (!context.mounted) {
    return RentalLocationResult.fail(
      RentalLocationStatus.error,
      'Impossible d’obtenir votre position.',
    );
  }

  // Triggers the system permission sheet when not yet decided.
  final permission = await RentalLocationService.requestOsPermission();

  if (permission == LocationPermission.deniedForever) {
    if (context.mounted) {
      await showRentalLocationModal(
        context,
        result: RentalLocationResult.fail(
          RentalLocationStatus.deniedForever,
          'La localisation est bloquée pour Mon Peya. Ouvrez les réglages et activez-la.',
        ),
      );
    }
    return RentalLocationResult.fail(
      RentalLocationStatus.deniedForever,
      'La localisation est bloquée pour Mon Peya. Ouvrez les réglages et activez-la.',
    );
  }

  if (permission == LocationPermission.denied) {
    if (context.mounted) {
      await showRentalLocationModal(
        context,
        result: RentalLocationResult.fail(
          RentalLocationStatus.denied,
          'Autorisez l’accès à votre position pour afficher les biens autour de vous.',
        ),
        onRetry: () => ensureRentalLocation(context, forceAsk: true),
      );
    }
    return RentalLocationResult.fail(
      RentalLocationStatus.denied,
      'Autorisez l’accès à votre position pour afficher les biens autour de vous.',
    );
  }

  final result = await RentalLocationService.requestAndGetPosition(
    forceRefresh: true,
  );

  if (!result.hasLocation && context.mounted) {
    await showRentalLocationModal(
      context,
      result: result,
      onRetry: () => ensureRentalLocation(context, forceAsk: true),
    );
  }

  return result;
}

/// First-step in-app modal: user taps Autoriser → OS permission prompt follows.
Future<bool> showRentalLocationAskModal(BuildContext context) async {
  final b = RentalTheme.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: b.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.my_location_rounded,
          color: RentalTheme.green,
          size: 36,
        ),
        title: Text(
          'Utiliser votre position ?',
          style: TextStyle(
            color: b.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Mr Immo a besoin de votre position pour afficher les biens autour de vous (rayon de 500 m) et vous situer sur la carte.',
          style: TextStyle(color: b.muted, fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Pas maintenant', style: TextStyle(color: b.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: RentalTheme.green,
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

/// Modal explaining location issues and offering retry / settings actions.
Future<void> showRentalLocationModal(
  BuildContext context, {
  required RentalLocationResult result,
  VoidCallback? onRetry,
}) {
  final status = result.status;
  final needsSettings = status == RentalLocationStatus.deniedForever ||
      status == RentalLocationStatus.serviceDisabled;
  final b = RentalTheme.of(context);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: b.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          status == RentalLocationStatus.serviceDisabled
              ? Icons.location_disabled_rounded
              : Icons.location_on_outlined,
          color: RentalTheme.green,
          size: 36,
        ),
        title: Text(
          'Position requise',
          style: TextStyle(
            color: b.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          result.message ??
              'Autorisez la localisation pour utiliser votre position actuelle.',
          style: TextStyle(color: b.muted, fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Fermer', style: TextStyle(color: b.muted)),
          ),
          if (needsSettings)
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (status == RentalLocationStatus.serviceDisabled) {
                  await RentalLocationService.openLocationSettings();
                } else {
                  await RentalLocationService.openAppSettings();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: RentalTheme.green,
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
                backgroundColor: RentalTheme.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
        ],
      );
    },
  );
}
