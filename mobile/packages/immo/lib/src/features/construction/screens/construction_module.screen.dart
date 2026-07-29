import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/auth/immo_module.session.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_module_shell.widget.dart';
import 'package:immo/src/features/construction/navigation/construction_main.navigation.dart';

/// Entry point for Mr Immo Construction inside Mon Peya.
class MrImmoConstructionScreen extends StatefulWidget {
  const MrImmoConstructionScreen({super.key});

  @override
  State<MrImmoConstructionScreen> createState() => _MrImmoConstructionScreenState();
}

class _MrImmoConstructionScreenState extends State<MrImmoConstructionScreen> {
  late final ImmoModuleSession _session;

  @override
  void initState() {
    super.initState();
    _session = ImmoModuleSession();
    _session.bootstrap();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImmoModuleSessionScope(
      session: _session,
      child: const ImmoModuleShell(
        primaryColor: ImmoBrand.constructionPrimary,
        moduleLabel: 'Mr Immo Construction',
        child: ConstructionMainNavigation(),
      ),
    );
  }
}
