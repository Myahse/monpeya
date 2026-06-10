import 'package:app/src/core/modules/app.module.dart';

/// Combines API modules (platform + partner) with bundled modules.
class ModuleMerger {
  const ModuleMerger._();

  static List<AppModule> merge({
    required ModuleLoadMode mode,
    required List<AppModule> remote,
    required List<AppModule> bundled,
  }) {
    switch (mode) {
      case ModuleLoadMode.bundledOnly:
        return _sorted(bundled);

      case ModuleLoadMode.remoteOnly:
        return _sorted(remote);

      case ModuleLoadMode.hybrid:
        return _mergeHybrid(remote: remote, bundled: bundled);
    }
  }

  static List<AppModule> _mergeHybrid({
    required List<AppModule> remote,
    required List<AppModule> bundled,
  }) {
    // Remote entries (platform + partner) override bundled modules with the same key.
    final byKey = <String, AppModule>{
      for (final module in bundled) module.moduleKey: module,
    };

    for (final module in remote) {
      byKey[module.moduleKey] = module;
    }

    return _sorted(byKey.values.toList());
  }

  static List<AppModule> _sorted(List<AppModule> modules) {
    final copy = List<AppModule>.from(modules);
    copy.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.name.compareTo(b.name);
    });
    return copy;
  }
}

class ModuleFetchStats {
  const ModuleFetchStats({
    required this.remoteCount,
    required this.bundledCount,
    required this.partnerCount,
    required this.platformCount,
  });

  final int remoteCount;
  final int bundledCount;
  final int partnerCount;
  final int platformCount;

  factory ModuleFetchStats.fromModules(List<AppModule> modules) {
    var partner = 0;
    var platform = 0;
    var bundled = 0;
    for (final module in modules) {
      switch (module.source) {
        case ModuleSource.partner:
          partner++;
        case ModuleSource.platform:
          platform++;
        case ModuleSource.bundled:
          bundled++;
      }
    }
    return ModuleFetchStats(
      remoteCount: partner + platform,
      bundledCount: bundled,
      partnerCount: partner,
      platformCount: platform,
    );
  }
}
