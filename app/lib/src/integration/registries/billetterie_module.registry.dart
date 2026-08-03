import 'package:billetterie/billetterie.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/features/shell/types/app_stack.types.dart';

/// Super-app adapter — maps catalog entries to Billetterie native routes.
class BilletterieModuleRegistry {
  BilletterieModuleRegistry._();

  static bool isNativeBilletterie(AppModule module) {
    if (module.url.startsWith('native:billetterie')) return true;
    return BilletterieModuleKeys.isBilletterieKey(module.moduleKey);
  }

  static String? stackRouteFor(AppModule module) {
    if (!isNativeBilletterie(module)) return null;
    return switch (module.moduleKey) {
      BilletterieModuleKeys.transport ||
      BilletterieModuleKeys.legacy ||
      'transport' =>
        AppStackRoute.billetterieTransport,
      BilletterieModuleKeys.event || 'event' => AppStackRoute.billetterieEvent,
      _ => module.url.contains('/event')
          ? AppStackRoute.billetterieEvent
          : AppStackRoute.billetterieTransport,
    };
  }
}
