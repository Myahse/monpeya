import 'package:flutter/material.dart';

import '../../host/immo_host_bridge.dart';
import '../auth/immo_module_session.dart';
import '../auth/immo_module_session_scope.dart';

/// Loading gate + Mon Peya session required screen — no in-module login.
class ImmoModuleShell extends StatelessWidget {
  const ImmoModuleShell({
    super.key,
    required this.primaryColor,
    required this.moduleLabel,
    required this.child,
  });

  final Color primaryColor;
  final String moduleLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);

    if (session.authFailed) {
      return _MonPeyaSessionRequired(
        session: session,
        primaryColor: primaryColor,
        moduleLabel: moduleLabel,
      );
    }

    return child;
  }
}

class _MonPeyaSessionRequired extends StatelessWidget {
  const _MonPeyaSessionRequired({
    required this.session,
    required this.primaryColor,
    required this.moduleLabel,
  });

  final ImmoModuleSession session;
  final Color primaryColor;
  final String moduleLabel;

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
              Icon(Icons.phone_android, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Session Mon Peya requise',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                session.error ??
                    'Connectez-vous à Mon Peya, puis rouvrez $moduleLabel.',
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
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
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
