import 'package:flutter/material.dart';
import 'package:peyapay/peyapay.dart';

import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/widgets/nteri_news_carousel.widget.dart';


class MonPeyaPeyapayHostAdapter implements PeyapayHostAuth {
  const MonPeyaPeyapayHostAdapter();

  static void register() {
    PeyapayHostBridge.auth = const MonPeyaPeyapayHostAdapter();
    PeyapayHostBridge.sessionChanges = MonPeyaSession.instance;
    PeyapayHostBridge.openRoute = (routeName) async {
      await rootNavKey.currentState?.pushNamed(routeName);
    };
    PeyapayHostBridge.buildNewsCarousel = (context, {height = 200}) {
      return NteriNewsCarousel(height: height);
    };
    PeyapayHostBridge.ensureRegisteredForTransaction = (BuildContext context) {
      return ModuleAuth.ensureRegistered(context);
    };
  }

  @override
  Future<bool> isSessionActive() async => MonPeyaSession.instance.isSessionActive;

  @override
  Future<bool> hasAccount() => AuthStore.hasAccount();

  @override
  Future<String?> getPhone() => AuthStore.getPhone();

  @override
  Future<String?> authToken() => AuthStore.authToken();
}

void notifyMonPeyaSessionChanged() => MonPeyaSession.instance.notifySessionChanged();

void activateMonPeyaSession() => MonPeyaSession.instance.activateSession();

void endMonPeyaSession() => MonPeyaSession.instance.endSession();
