import 'package:flutter/material.dart';

import 'package:app/src/core/modules/app.module.dart';

/// Asset path for a module tile icon, or null to use [moduleIconData] fallback.
String? moduleIconAsset({String? moduleKey, String? iconKey}) {
  final key = (moduleKey ?? iconKey ?? '').toLowerCase();
  return switch (key) {
    'real-estate' ||
    'rental' ||
    'home' ||
    'immo-rental' ||
    'immo/rental' ||
    'mr-immo-rental' =>
      'packages/immo/assets/logo/immo/rental.png',
    'construction' ||
    'build' ||
    'immo-construction' ||
    'immo/construction' ||
    'mr-immo-construction' =>
      'packages/immo/assets/logo/immo/construction.png',
    'collection' ||
    'immo-collection' ||
    'immo/collection' ||
    'mr-immo-collection' =>
      'packages/immo/assets/logo/immo/collection.png',
    'leadway' ||
    'leadway-assurance' ||
    'leadway/assurance' =>
      'packages/leadway/assets/logo/leadway.png',
    'grenier' ||
    'mon-grenier' ||
    'mon_grenier' =>
      null,
    _ => _iconKeyAsset(iconKey),
  };
}

String? _iconKeyAsset(String? iconKey) {
  if (iconKey == null) return null;
  return switch (iconKey.toLowerCase()) {
    'immo-rental' => 'packages/immo/assets/logo/immo/rental.png',
    'immo-construction' => 'packages/immo/assets/logo/immo/construction.png',
    'immo-collection' => 'packages/immo/assets/logo/immo/collection.png',
    'leadway' => 'packages/leadway/assets/logo/leadway.png',
    _ => null,
  };
}

bool isImmoBrandedModuleIcon({String? moduleKey, String? iconKey}) {
  final asset = moduleIconAsset(moduleKey: moduleKey, iconKey: iconKey);
  return asset != null && asset.contains('/immo/');
}

bool isLeadwayBrandedModuleIcon({String? moduleKey, String? iconKey}) {
  final asset = moduleIconAsset(moduleKey: moduleKey, iconKey: iconKey);
  return asset != null && asset.contains('/leadway/');
}


IconData moduleIconData(String iconKey) {
  return switch (iconKey.toLowerCase()) {
    'home' || 'real_estate' || 'rental' || 'immo-rental' => Icons.home_work_outlined,
    'construction' || 'build' || 'immo-construction' => Icons.construction_outlined,
    'shield' || 'insurance' || 'leadway' || 'sim' || 'sim-assurance' => Icons.shield_outlined,
    'school' || 'education' => Icons.school_outlined,
    'cart' || 'marketplace' || 'shop' => Icons.shopping_bag_outlined,
    'ticket' ||
    'billetterie' ||
    'billetterie-transport' ||
    'billetterie/transport' =>
      Icons.directions_bus_outlined,
    'billetterie-event' ||
    'billetterie/event' ||
    'event' =>
      Icons.confirmation_number_outlined,
    'collection' || 'bookmark' || 'immo-collection' => Icons.collections_bookmark_outlined,
    'wallet' || 'payment' => Icons.account_balance_wallet_outlined,
    'apartment' => Icons.apartment_outlined,
    'grenier' || 'mon-grenier' || 'mon_grenier' => Icons.storefront_outlined,
    _ => Icons.widgets_outlined,
  };
}


class ModuleIcon extends StatelessWidget {
  const ModuleIcon({
    super.key,
    required this.iconKey,
    this.moduleKey,
    this.size = 28,
    this.color,
    this.fit = BoxFit.contain,
  });

  ModuleIcon.forModule(
    AppModule module, {
    super.key,
    this.size = 28,
    this.color,
    this.fit = BoxFit.contain,
  })  : iconKey = module.icon,
        moduleKey = module.moduleKey;

  final String iconKey;
  final String? moduleKey;
  final double size;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = moduleIconAsset(moduleKey: moduleKey, iconKey: iconKey);
    if (asset != null) {
      final errorIcon = Icon(
        moduleIconData(iconKey),
        size: size,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

      if (!isImmoBrandedModuleIcon(moduleKey: moduleKey, iconKey: iconKey) &&
          !isLeadwayBrandedModuleIcon(moduleKey: moduleKey, iconKey: iconKey)) {
        return Image.asset(
          asset,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => errorIcon,
        );
      }

      final scale =
          isLeadwayBrandedModuleIcon(moduleKey: moduleKey, iconKey: iconKey)
              ? 1.18
              : 1.38;

      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: SizedBox(
          width: size,
          height: size,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => errorIcon,
            ),
          ),
        ),
      );
    }

    return Icon(
      moduleIconData(iconKey),
      size: size,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
}
