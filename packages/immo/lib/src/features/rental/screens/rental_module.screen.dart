import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/auth/rental.session.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/widgets/rental_module_shell.widget.dart';

/// Entry point for Mr Immo Location inside Mon Peya.
class MrImmoRentalScreen extends StatefulWidget {
  const MrImmoRentalScreen({super.key});

  @override
  State<MrImmoRentalScreen> createState() => _MrImmoRentalScreenState();
}

class _MrImmoRentalScreenState extends State<MrImmoRentalScreen> {
  late final RentalSession _session;

  @override
  void initState() {
    super.initState();
    _session = RentalSession();
    _session.bootstrap();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RentalSessionScope(
      session: _session,
      child: const RentalModuleShell(),
    );
  }
}
