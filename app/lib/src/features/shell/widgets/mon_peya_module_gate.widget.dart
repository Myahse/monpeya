import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/services/module_launcher.service.dart';

class MonPeyaModuleGate extends StatelessWidget {
  const MonPeyaModuleGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

Future<void> openModuleIfRegistered(
  BuildContext context,
  AppModule module,
) async {
  await ModuleLauncher.open(context, module);
}
