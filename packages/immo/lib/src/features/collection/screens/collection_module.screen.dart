import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/shared/auth/immo_module.session.dart';
import 'package:immo/src/shared/auth/scopes/immo_module_session.scope.dart';
import 'package:immo/src/shared/widgets/immo_module_shell.widget.dart';
import 'package:immo/src/features/collection/navigation/collection.navigator.dart';

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
