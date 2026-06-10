import 'package:app/src/core/modules/app.module.dart';

/// Bundled modules ship with the app for offline dev, QA, and demo builds.
/// Partners never touch this file — they register modules through the API.
class BundledModules {
  BundledModules._();

  static const catalog = [
    AppModule(
      id: 1,
      moduleKey: 'real-estate',
      name: 'Mr Immo Location',
      icon: 'immo-rental',
      url: 'native:immo/rental',
      type: ModuleLaunchType.native,
      source: ModuleSource.bundled,
      sortOrder: 1,
    ),
    AppModule(
      id: 2,
      moduleKey: 'construction',
      name: 'Mr Immo Construction',
      icon: 'immo-construction',
      url: 'native:immo/construction',
      type: ModuleLaunchType.native,
      source: ModuleSource.bundled,
      sortOrder: 2,
    ),
    AppModule(
      id: 3,
      moduleKey: 'collection',
      name: 'Mr Immo Collection',
      icon: 'immo-collection',
      url: 'native:immo/collection',
      type: ModuleLaunchType.native,
      source: ModuleSource.bundled,
      sortOrder: 3,
    ),
    AppModule(
      id: 5,
      moduleKey: 'billetterie',
      name: 'Billetterie',
      icon: 'ticket',
      url: 'native:billetterie',
      type: ModuleLaunchType.native,
      source: ModuleSource.bundled,
      sortOrder: 5,
    ),
  ];
}
