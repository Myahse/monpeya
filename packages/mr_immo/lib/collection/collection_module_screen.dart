import 'package:flutter/material.dart';

import '../immo_brand.dart';
import '../shared/auth/immo_module_session.dart';
import '../shared/auth/immo_module_session_scope.dart';
import '../shared/widgets/immo_module_shell.dart';
import 'navigation/collection_navigator.dart';

/// Entry point for Mr Immo Collection inside Mon Peya.
class MrImmoCollectionScreen extends StatefulWidget {
  const MrImmoCollectionScreen({super.key});

  @override
  State<MrImmoCollectionScreen> createState() => _MrImmoCollectionScreenState();
}

class _MrImmoCollectionScreenState extends State<MrImmoCollectionScreen> {
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
        primaryColor: ImmoBrand.collectionPrimary,
        moduleLabel: 'Mr Immo Collection',
        child: CollectionNavigator(),
      ),
    );
  }
}
