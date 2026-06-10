import 'package:flutter/material.dart';

/// Services open without registration; payment flows verify sign-in at checkout.
class MonPeyaModuleGate extends StatelessWidget {
  const MonPeyaModuleGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Opens a service module from the super-app shell (no upfront registration).
void openModule(BuildContext context, VoidCallback onOpen) {
  onOpen();
}

/// @deprecated Use [openModule] — kept for existing call sites.
Future<void> openModuleIfRegistered(
  BuildContext context,
  VoidCallback openModuleCallback,
) async {
  if (context.mounted) openModuleCallback();
}
