import 'package:flutter/foundation.dart';

class MonPeyaSession extends ChangeNotifier {
  MonPeyaSession._();

  static final MonPeyaSession instance = MonPeyaSession._();

  bool _sessionActive = false;
  int _authOverlayDepth = 0;

  bool get isSessionActive => _sessionActive;

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
    _authOverlayDepth = 0;
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
