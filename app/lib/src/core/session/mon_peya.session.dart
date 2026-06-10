import 'package:flutter/foundation.dart';

/// In-memory Mon Peya login session (PIN validated). Cleared on logout or app restart.
class MonPeyaSession extends ChangeNotifier {
  MonPeyaSession._();

  static final MonPeyaSession instance = MonPeyaSession._();

  bool _sessionActive = false;
  int _authOverlayDepth = 0;

  bool get isSessionActive => _sessionActive;

  /// True while a full-screen login / registration route is open.
  bool get isAuthOverlayVisible => _authOverlayDepth > 0;

  void beginAuthOverlay() {
    _authOverlayDepth++;
    notifyListeners();
  }

  void endAuthOverlay() {
    if (_authOverlayDepth > 0) {
      _authOverlayDepth--;
      notifyListeners();
    }
  }

  void activateSession() {
    if (_sessionActive) return;
    _sessionActive = true;
    notifyListeners();
  }

  void endSession() {
    if (!_sessionActive) return;
    _sessionActive = false;
    notifyListeners();
  }

  void notifySessionChanged() => notifyListeners();
}
