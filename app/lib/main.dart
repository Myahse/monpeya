import 'package:flutter/widgets.dart';

import 'package:app/src/core/config/mon_peya_env.dart';
import 'package:app/app.dart';
import 'package:app/src/core/system/system_ui.config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureMonPeyaSystemUi();
  await MonPeyaEnv.load();
  runApp(const MonPeyaSuperApp());
}
