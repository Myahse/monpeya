import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';
import 'package:app/src/core/utils/status_bar.util.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';
import 'package:app/src/features/shell/widgets/dynamic_modules_grid.widget.dart';

class MonPeyaMyServicesScreen extends StatefulWidget {
  const MonPeyaMyServicesScreen({super.key});

  @override
  State<MonPeyaMyServicesScreen> createState() => _MonPeyaMyServicesScreenState();
}

class _MonPeyaMyServicesScreenState extends State<MonPeyaMyServicesScreen> {
  final _repository = ModuleRepository();
  late Future<ModuleFetchResult> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _repository.fetchModulesResult();
  }

  void _openModule(AppModule module) {
    AppStackScope.maybeOf(context)?.openModule(module);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                    onTap: () => Navigator.of(context).maybePop(),
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
            child: FutureBuilder<ModuleFetchResult>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                final loading = snapshot.connectionState != ConnectionState.done;
                final modules = snapshot.data?.modules ?? const <AppModule>[];

                return ListView(
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
                      loading
                          ? 'Chargement...'
                          : 'Services disponibles sur votre compte',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    if (loading)
                      const ModulesLoadingGrid()
                    else
                      DynamicModulesGrid(
                        modules: modules,
                        onOpenModule: _openModule,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
