import 'package:flutter/material.dart';

import 'package:immo/src/core/host/immo_host.bridge.dart';
import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/rental.session.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/navigation/rental_main.navigation.dart';

/// Shows loading, then [RentalMainNavigation]. Session sync uses Mon Peya only — no in-module login.
class RentalModuleShell extends StatelessWidget {
  const RentalModuleShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = RentalSessionScope.of(context);

    if (session.authFailed) {
      return _MonPeyaSessionRequired(session: session);
    }

    return const RentalMainNavigation();
  }
}

class _MonPeyaSessionRequired extends StatelessWidget {
  const _MonPeyaSessionRequired({required this.session});

  final RentalSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => ImmoHostBridge.exitModule(context),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const Spacer(),
              const Icon(Icons.phone_android, size: 48, color: ImmoBrand.rentalPrimary),
              const SizedBox(height: 16),
              const Text(
                'Session Mon Peya requise',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                session.error ??
                    'Connectez-vous à Mon Peya avec le même téléphone et code PIN, puis rouvrez Mr Immo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              if (session.phone != null) ...[
                const SizedBox(height: 12),
                Text(
                  session.phone!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () => ImmoHostBridge.exitModule(context),
                style: FilledButton.styleFrom(backgroundColor: ImmoBrand.rentalPrimary),
                child: const Text('Retour à Mon Peya'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: session.bootstrap,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
