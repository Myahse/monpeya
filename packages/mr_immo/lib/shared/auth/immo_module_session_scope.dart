import 'package:flutter/material.dart';

import 'immo_module_session.dart';

class ImmoModuleSessionScope extends InheritedNotifier<ImmoModuleSession> {
  const ImmoModuleSessionScope({
    super.key,
    required ImmoModuleSession session,
    required super.child,
  }) : super(notifier: session);

  static ImmoModuleSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ImmoModuleSessionScope>();
    assert(scope != null, 'ImmoModuleSessionScope not found');
    return scope!.notifier!;
  }
}
