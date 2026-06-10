import 'package:flutter/material.dart';

import 'auth/rental_session.dart';
import 'auth/rental_session_scope.dart';
import 'widgets/rental_module_shell.dart';

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
