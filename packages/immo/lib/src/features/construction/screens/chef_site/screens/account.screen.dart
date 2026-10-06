import 'package:flutter/material.dart';

import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = ImmoModuleSessionScope.of(context);
    final name = (session.displayName ?? '').trim();
    return ImmoAccountView(
      moduleLabel: 'Mr Immo Construction',
      name: name.isEmpty ? 'Invité' : name,
      phone: session.phone,
      roleLabel: 'Chef de chantier',
      guest: session.guestMode,
    );
  }
}
