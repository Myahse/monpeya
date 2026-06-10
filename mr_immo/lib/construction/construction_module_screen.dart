import 'package:flutter/material.dart';

import '../immo_brand.dart';
import '../shared/auth/immo_module_session.dart';
import '../shared/auth/immo_module_session_scope.dart';
import '../shared/widgets/immo_module_shell.dart';
import 'navigation/construction_main_navigation.dart';

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
