enum ModuleSource {
  bundled,
  platform,
  partner,
}

extension ModuleSourceParsing on ModuleSource {
  static ModuleSource fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'partner' || 'external' => ModuleSource.partner,
      'platform' || 'internal' || 'djogana' => ModuleSource.platform,
      'bundled' || 'local' || 'asset' => ModuleSource.bundled,
      _ => ModuleSource.platform,
    };
  }
}

enum ModuleLaunchType {
  web,
  native,
}

class AppModule {
  const AppModule({
    required this.id,
    required this.moduleKey,
    required this.name,
    required this.icon,
    required this.url,
    this.type = ModuleLaunchType.web,
    this.source = ModuleSource.platform,
    this.partnerId,
    this.sortOrder = 0,
    this.active = true,
  });

  final int id;
  final String moduleKey;
  final String name;
  final String icon;
  final String url;
  final ModuleLaunchType type;
  final ModuleSource source;
  final String? partnerId;
  final int sortOrder;
  final bool active;

  bool get isAssetModule => url.startsWith('asset:');
  bool get isPartnerModule => source == ModuleSource.partner;

  String get assetPath {
    if (!isAssetModule) return url;
    return 'assets/${url.substring('asset:'.length)}';
  }

  Uri resolvedUri({String? authToken}) {
    if (isAssetModule) {
      throw StateError('Asset modules must be loaded via loadFlutterAsset.');
    }

    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);
    params.putIfAbsent('embedded', () => '1');
    params.putIfAbsent('platform', () => 'flutter');
    params.putIfAbsent('moduleKey', () => moduleKey);
    if (partnerId != null && partnerId!.isNotEmpty) {
      params.putIfAbsent('partnerId', () => partnerId!);
    }
    if (authToken != null && authToken.isNotEmpty) {
      params.putIfAbsent('token', () => authToken);
    }
    return uri.replace(queryParameters: params);
  }

  factory AppModule.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] as String?)?.toLowerCase();
    final id = json['id'];
    final key = (json['moduleKey'] as String?) ?? (json['key'] as String?) ?? 'module-$id';

    return AppModule(
      id: id is int ? id : int.tryParse('$id') ?? 0,
      moduleKey: key,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? 'widgets',
      url: json['url'] as String,
      type: typeRaw == 'native' ? ModuleLaunchType.native : ModuleLaunchType.web,
      source: ModuleSourceParsing.fromString(json['source'] as String?),
      partnerId: json['partnerId'] as String?,
      sortOrder: json['sortOrder'] as int? ?? json['order'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'moduleKey': moduleKey,
        'name': name,
        'icon': icon,
        'url': url,
        'type': type == ModuleLaunchType.native ? 'native' : 'web',
        'source': source.apiValue,
        if (partnerId != null) 'partnerId': partnerId,
        'sortOrder': sortOrder,
        'active': active,
      };
}

extension ModuleSourceApi on ModuleSource {
  String get apiValue => switch (this) {
        ModuleSource.partner => 'partner',
        ModuleSource.platform => 'platform',
        ModuleSource.bundled => 'bundled',
      };
}
