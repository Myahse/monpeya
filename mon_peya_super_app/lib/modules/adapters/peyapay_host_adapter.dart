import 'package:peya_pay/host/peyapay_host_bridge.dart';

import '../../app/routing/routes.dart';
import '../../app/storage/auth_store.dart';
import '../../screens/app_stack/widgets/nteri_news_carousel.dart';

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
