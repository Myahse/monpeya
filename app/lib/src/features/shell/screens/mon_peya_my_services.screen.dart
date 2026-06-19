import 'package:flutter/material.dart';

import 'package:app/src/core/navigation/app.navigation.dart';
import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';
import 'package:app/src/core/utils/status_bar.util.dart';
import 'package:app/src/features/shell/services/module_launcher.service.dart';
import 'package:app/src/features/shell/widgets/dynamic_modules_grid.widget.dart';

class MonPeyaMyServicesScreen extends StatelessWidget {
  const MonPeyaMyServicesScreen({super.key});

  void _openModule(BuildContext context, AppModule module) {
    ModuleLauncher.open(context, module);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final modules = ModuleRepository.modules;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, shellContentTop(context) + 12, 16, 12),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => AppNavigation.pop(context),
                    borderRadius: BorderRadius.circular(999),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.chevron_left, size: 26),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Mon espace personnel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40, height: 40),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  'Mes services',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Services disponibles sur votre compte',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                DynamicModulesGrid(
                  modules: modules,
                  onOpenModule: (module) => _openModule(context, module),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
