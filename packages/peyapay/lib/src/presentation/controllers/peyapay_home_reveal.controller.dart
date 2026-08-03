import 'package:flutter/foundation.dart';

/// Lets the host tab shell play the PeyaPay actions card enter/exit animation
/// before switching away (IndexedStack would otherwise hide it instantly).
class PeyapayHomeRevealController {
  Future<void> Function()? _exit;
  VoidCallback? _enter;

  void attach({
    required Future<void> Function() exit,
    required VoidCallback enter,
  }) {
    _exit = exit;
    _enter = enter;
  }

  void detach({
    Future<void> Function()? exit,
    VoidCallback? enter,
  }) {
    if (exit == null || identical(_exit, exit)) _exit = null;
    if (enter == null || identical(_enter, enter)) _enter = null;
  }

  Future<void> playExit() async {
    final fn = _exit;
    if (fn != null) await fn();
  }

  void playEnter() => _enter?.call();
}
