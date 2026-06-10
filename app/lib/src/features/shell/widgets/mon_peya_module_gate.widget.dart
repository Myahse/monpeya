import 'package:flutter/material.dart';

import 'package:app/src/core/auth/auth.navigation.dart';
import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/auth/presentation/login_pin/screens/login_pin.screen.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

/// Ensures Mon Peya sign-in before native services. Opens PIN or registration automatically.
class MonPeyaModuleGate extends StatefulWidget {
  const MonPeyaModuleGate({super.key, required this.child});

  final Widget child;

  @override
  State<MonPeyaModuleGate> createState() => _MonPeyaModuleGateState();
}

class _MonPeyaModuleGateState extends State<MonPeyaModuleGate> {
  bool _authFlowOpen = false;

  @override
  void initState() {
    super.initState();
    MonPeyaSession.instance.addListener(_onSessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  @override
  void dispose() {
    MonPeyaSession.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
    if (!MonPeyaSession.instance.isSessionActive) {
      _ensureSession();
    }
  }

  Future<void> _ensureSession() async {
    if (_authFlowOpen || MonPeyaSession.instance.isSessionActive || !mounted) return;

    _authFlowOpen = true;
    try {
      if (await AuthStore.hasAccount()) {
        final phone = await AuthStore.getPhone();
        if (!mounted) return;
        await pushFullScreenAuth<bool>(
          context,
          LoginPinScreen(embeddedInModule: true, phoneNumber: phone),
        );
      } else {
        await ModuleAuth.ensureRegistered(context);
      }
    } finally {
      _authFlowOpen = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MonPeyaSession.instance.isSessionActive) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _exitToMonPeyaHome(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

void _exitToMonPeyaHome(BuildContext context) {
  final stack = AppStackScope.maybeOf(context);
  if (stack != null && stack.canGoBack) {
    stack.goBack();
    return;
  }
  Navigator.of(context).maybePop();
}

/// Call before navigating to a module from the super-app shell.
Future<void> openModuleIfRegistered(
  BuildContext context,
  VoidCallback openModule,
) async {
  final ok = await ModuleAuth.ensureRegistered(context);
  if (context.mounted && ok) openModule();
}
