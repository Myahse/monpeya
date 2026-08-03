import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/auth/rental.session.dart';

class RentalSessionScope extends InheritedNotifier<RentalSession> {
  const RentalSessionScope({
    super.key,
    required RentalSession session,
    required super.child,
  }) : super(notifier: session);

  static RentalSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RentalSessionScope>();
    assert(scope != null, 'RentalSessionScope not found');
    return scope!.notifier!;
  }

  static RentalSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RentalSessionScope>()?.notifier;
}
