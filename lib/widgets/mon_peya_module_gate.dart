import 'package:flutter/material.dart';

import '../app/module_auth.dart';
import '../app/routing/routes.dart';
import '../app/storage/auth_store.dart';
import '../screens/app_stack/app_stack_scope.dart';

/// Ensures Mon Peya sign-in before native services. No loading spinner — opens immediately.
class MonPeyaModuleGate extends StatefulWidget {
  const MonPeyaModuleGate({super.key, required this.child});

  final Widget child;

  @override
  State<MonPeyaModuleGate> createState() => _MonPeyaModuleGateState();
}

class _MonPeyaModuleGateState extends State<MonPeyaModuleGate> {
  bool _checked = false;
  bool _registered = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await AuthStore.isRegistered();
    if (!mounted) return;
    setState(() {
      _registered = ok;
      _checked = true;
    });
  }

  Future<void> _openMonPeyaLogin() async {
    await rootNavKey.currentState?.pushNamed(Routes.phoneInput);
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    if (_checked && !_registered) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconButton(
                  alignment: Alignment.centerLeft,
                  onPressed: () => _exitToMonPeyaHome(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                const Icon(Icons.account_circle_outlined, size: 56, color: Color(0xFF0284C7)),
                const SizedBox(height: 16),
                const Text(
                  'Connexion Mon Peya requise',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Connectez-vous avec votre téléphone et votre code PIN Mon Peya pour accéder à ce service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _openMonPeyaLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006D56),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Se connecter à Mon Peya'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _exitToMonPeyaHome(context),
                  child: const Text('Retour'),
                ),
              ],
            ),
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
