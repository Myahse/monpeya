import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


Future<void> configureMonPeyaSystemUi() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

SystemUiOverlayStyle monPeyaSystemUiOverlay(Brightness brightness) {
  final darkIcons = brightness == Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
    statusBarBrightness: darkIcons ? Brightness.light : Brightness.dark,
    systemNavigationBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
  );
}
