import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/auth/presentation/login_pin/screens/login_pin.screen.dart';
import 'package:app/src/features/auth/presentation/phone_input/screens/phone_input.screen.dart';

/// PeyaPay tab: full-screen PIN or registration — bottom nav hidden until session is active.
class PeyapayTabShell extends StatefulWidget {
  const PeyapayTabShell({super.key});

  @override
  State<PeyapayTabShell> createState() => _PeyapayTabShellState();
}

class _PeyapayTabShellState extends State<PeyapayTabShell> {
  bool? _hasAccount;

  @override
  void initState() {
    super.initState();
    MonPeyaSession.instance.addListener(_onSessionChanged);
    _refreshAccountFlag();
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
      _refreshAccountFlag();
    }
  }

  Future<void> _refreshAccountFlag() async {
    final has = await AuthStore.hasAccount();
    if (!mounted) return;
    setState(() => _hasAccount = has);
  }

  @override
  Widget build(BuildContext context) {
    if (MonPeyaSession.instance.isSessionActive) {
      return const PeyapayScreen();
    }

    final cs = Theme.of(context).colorScheme;
    final hasAccount = _hasAccount;

    if (hasAccount == true) {
      return const LoginPinScreen(embeddedInModule: true);
    }

    if (hasAccount == false) {
      return const PhoneInputScreen(embeddedInModule: true);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
