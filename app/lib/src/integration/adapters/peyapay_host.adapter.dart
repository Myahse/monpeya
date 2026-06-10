import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/widgets/nteri_news_carousel.widget.dart';

/// Connects Mon Peya shell auth, routes, and shared UI to the Peya Pay package.
class MonPeyaPeyapayHostAdapter implements PeyapayHostAuth {
  const MonPeyaPeyapayHostAdapter();

  static void register() {
    PeyapayHostBridge.auth = const MonPeyaPeyapayHostAdapter();
    PeyapayHostBridge.openRoute = (routeName) async {
      await rootNavKey.currentState?.pushNamed(routeName);
    };
    PeyapayHostBridge.buildNewsCarousel = (context, {height = 200}) {
      return NteriNewsCarousel(height: height);
    };
  }

  @override
  Future<bool> isRegistered() => AuthStore.isRegistered();
}
